"""Primitive script: chunk-documents

Takes a JSON array of documents (from read-skill-documents or similar)
and splits each into bounded chunks by markdown headings. Each chunk
includes the document metadata plus a section of content sized for
small model context windows.

Input: JSON array of {name, type, path, content} objects
Output: JSON array of {name, type, chunk_index, section_heading, content} objects
        where each content is ≤ max_chars (default 6000)
"""

import json
import re
import sys


def split_oversized(text: str, max_chars: int) -> list[str]:
    """Split an oversized text block at paragraph boundaries."""
    paragraphs = re.split(r'\n\n+', text)
    pieces = []
    current = []
    current_len = 0

    for para in paragraphs:
        para = para.strip()
        if not para:
            continue
        if current_len + len(para) > max_chars and current:
            pieces.append("\n\n".join(current))
            current = [para]
            current_len = len(para)
        else:
            current.append(para)
            current_len += len(para)

    if current:
        pieces.append("\n\n".join(current))

    # If any piece is still oversized, split at line boundaries
    final = []
    for piece in pieces:
        if len(piece) <= max_chars:
            final.append(piece)
        else:
            lines = piece.split('\n')
            buf = []
            buf_len = 0
            for line in lines:
                if buf_len + len(line) > max_chars and buf:
                    final.append("\n".join(buf))
                    buf = [line]
                    buf_len = len(line)
                else:
                    buf.append(line)
                    buf_len += len(line)
            if buf:
                final.append("\n".join(buf))

    return final


def chunk_by_headings(text: str, max_chars: int = 3000) -> list[dict]:
    """Split markdown text into chunks at heading boundaries."""
    # Split on markdown headings (##, ###, etc.)
    parts = re.split(r'(^#{1,4}\s+.+$)', text, flags=re.MULTILINE)

    chunks = []
    current_heading = "Preamble"
    current_content = []
    current_len = 0

    def flush():
        nonlocal current_content, current_len
        if not current_content:
            return
        merged = "\n".join(current_content)
        if len(merged) <= max_chars:
            chunks.append({
                "section_heading": current_heading,
                "content": merged
            })
        else:
            # Sub-split oversized sections at paragraph/line boundaries
            for piece in split_oversized(merged, max_chars):
                chunks.append({
                    "section_heading": current_heading,
                    "content": piece
                })
        current_content = []
        current_len = 0

    for part in parts:
        part = part.strip()
        if not part:
            continue

        if re.match(r'^#{1,4}\s+', part):
            # This is a heading — flush current chunk if non-empty
            flush()
            current_heading = part.lstrip('#').strip()
            current_content = [part]
            current_len = len(part)
        else:
            # Content block — check if adding it exceeds max_chars
            if current_len + len(part) > max_chars and current_content:
                flush()
                current_content = [part]
                current_len = len(part)
            else:
                current_content.append(part)
                current_len += len(part)

    # Flush remaining
    flush()

    return chunks


def extract_upstream_documents(data: dict) -> list:
    """Extract document list from upstream agent output.

    Handles two llm-orc formats:
    1. Schema path: {dependencies: {agent: {response: ...}}, input_data: ...}
    2. Standard path: {input: "<ScriptAgentInput JSON>", parameters: ..., context: ...}
    """
    # Check for dependencies at top level (schema path)
    dependencies = data.get("dependencies", {})
    if dependencies:
        return extract_from_dependencies(dependencies)

    # Check for standard wrapper: {input: "<json string>", parameters: ...}
    wrapped_input = data.get("input")
    if isinstance(wrapped_input, str):
        try:
            inner = json.loads(wrapped_input)
            if isinstance(inner, dict):
                inner_deps = inner.get("dependencies", {})
                if inner_deps:
                    return extract_from_dependencies(inner_deps)
        except (json.JSONDecodeError, TypeError):
            pass

    # Fallback: try input_data field
    input_data = data.get("input_data", "[]")
    try:
        docs = json.loads(input_data) if isinstance(input_data, str) else input_data
        return docs if isinstance(docs, list) else []
    except json.JSONDecodeError:
        return []


def extract_from_dependencies(dependencies: dict) -> list:
    """Extract document list from a dependencies dict."""
    for dep_name, dep_data in dependencies.items():
        upstream = dep_data.get("response", "")
        if isinstance(upstream, list):
            return upstream
        elif isinstance(upstream, str):
            try:
                result = json.loads(upstream)
                return result if isinstance(result, list) else []
            except (json.JSONDecodeError, TypeError):
                return []
        else:
            return []
    return []


def process(input_text: str) -> str:
    """Chunk documents into bounded sections."""
    try:
        data = json.loads(input_text)
    except json.JSONDecodeError:
        return json.dumps({"error": "Invalid JSON input"})

    if isinstance(data, dict):
        documents = extract_upstream_documents(data)
    elif isinstance(data, list):
        documents = data
    else:
        return json.dumps({"error": "Expected JSON array of documents"})

    if not isinstance(documents, list):
        return json.dumps({"error": f"Expected list, got {type(documents).__name__}"})

    params = data.get("parameters", {}) if isinstance(data, dict) else {}
    max_chars = params.get("max_chars", 6000)
    min_chars = params.get("min_chars", 50)

    all_chunks = []
    for doc in documents:
        if not isinstance(doc, dict) or "content" not in doc:
            continue

        doc_chunks = chunk_by_headings(doc["content"], max_chars=max_chars)
        # Filter out tiny chunks (e.g. bare section headings with no content)
        doc_chunks = [c for c in doc_chunks if len(c["content"]) >= min_chars]

        for i, chunk in enumerate(doc_chunks):
            all_chunks.append({
                "name": doc.get("name", "unknown"),
                "type": doc.get("type", "unknown"),
                "chunk_index": i,
                "total_chunks": len(doc_chunks),
                "section_heading": chunk["section_heading"],
                "content": chunk["content"]
            })

    return json.dumps(all_chunks)


if __name__ == "__main__":
    input_text = sys.stdin.read()
    result = process(input_text)
    print(result)
