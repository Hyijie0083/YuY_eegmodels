# Research Workflow Configuration Template

> Copy this file to your project directory as `WORKFLOW.md` and customize the parameters.

## Project Configuration

```yaml
# ============================================
# PROJECT SETTINGS - CUSTOMIZE THESE
# ============================================

project:
  name: "RateMyProfessor Analysis"
  working_directory: "C:/Users/profh/Desktop/Courses/大数据心理学/AI-Python-for-Deep-Learning/基于RateMyProfessor13G大数据的可解释机器学习分析"
  
data:
  input_file: "RMP_Moral_Processed_Professor_Moral_Tags.csv"
  file_size_note: "Large file (>6GB), use chunked processing"
  target_variable: "star_rating"

keywords:
  primary: "ratemyprofessor"
  secondary:
    - "teaching evaluation"
    - "student evaluation of teachers"
    - "SET"

# ============================================
# OUTPUT FILES
# ============================================

outputs:
  step2_literature: "step2-ratemyprofessor-SET-literature.xlsx"
  step3_review: "step3-ratemyprofessor-文献综述.docx"
  step4_hypotheses: "step4-ratemyprofessor-研究假设.docx"
  step5_grants: "step5-ratemyprofessor-寻找研究经费.docx"
  step8_eda: "step8-ratemyprofessor-数据分析.docx"
  step11_report: "rate-myprofessor_report3.tex"
  step12_review: "rate-myprofessor_report3-review.docx"
  step13_poster: "step13-rate-myprofessor_poster3.tex"
  step14_slides: "step14-rate-myprofessor_slides3.pptx"
  step16_apa_check: "apa-format-check.docx"
  step17_stat_check: "rate-myprofessor_report3-统计分析检查.docx"
  step18_cover_letter: "cover-letter.docx"
  step19_rebuttal: "rate-myprofessor_report3-rebuttal.docx"
  step19_editor_response: "ratemyprofessor-editor-response-letter.docx"

# ============================================
# SKILL PATHS
# ============================================

skills:
  research_ideation: "AI-Research-SKILLs-main/21-research-ideation"
  literature_databases: "literature-search-skills-databases"
  lit_review: "scientific-skills/literature-review"
  hypothesis_generation: "scientific-skills/hypothesis-generation"
  research_grants: "scientific-skills/research-grants"
  data_processing: "AI-Research-SKILLs-main/05-data-processing"
  eda: "scientific-skills/exploratory-data-analysis"
  mlops: "AI-Research-SKILLs-main/13-mlops"
  shap: "scientific-skills/shap"
  paper_writing: "AI-Research-SKILLs-main/20-ml-paper-writing"
  peer_review: "peer-review"
  latex_posters: "scientific-skills/latex-posters"
  scientific_slides: "scientific-skills/scientific-slides"
  apa_style: "apa-styles-agent-skills/apa-style-citation"
  statistical_analysis: "scientific-thinking-statistical-analysis"
  cover_letter: "resumeskills/cover-letter-generator"
  rebuttal: "rebuttal"
```

---

## Step-by-Step Execution Checklist

### Phase 1: Research Planning ☐

- [ ] **Step 1: Research Ideation**
  - Skill: `research-ideation`
  - Input: Keywords (ratemyprofessor, SET)
  - Output: Research ideas, target journals
  - Command: `skill(name="research-ideation", user_message="Generate research ideas for ratemyprofessor and student evaluation of teachers")`

- [ ] **Step 2: Literature Search**
  - Skills: All database skills (parallel execution)
  - Databases: PubMed, OpenAlex, Perplexity, PubChem, GWAS, HMDB, KEGG
  - Output: `step2-ratemyprofessor-SET-literature.xlsx`
  - Command: Fire all database searches in parallel

- [ ] **Step 3: Literature Review**
  - Skill: `lit-review`
  - Input: Literature Excel file
  - Output: `step3-ratemyprofessor-文献综述.docx`

- [ ] **Step 4: Hypothesis Generation**
  - Skill: `hypothesis-generation`
  - Output: `step4-ratemyprofessor-研究假设.docx`

- [ ] **Step 5: Research Grants**
  - Skill: `research-grants`
  - Output: `step5-ratemyprofessor-寻找研究经费.docx`

### Phase 2: Data & Analysis ☐

- [ ] **Step 6: Experiment Design**
  - Note: Human execution required
  - Deliverables: Protocol, data collection plan

- [ ] **Step 7: Data Preprocessing**
  - Skill: `data-processing`
  - Note: Large file (>6GB), use chunked reading
  - Code pattern:
    ```python
    import pandas as pd
    for chunk in pd.read_csv('file.csv', chunksize=100000):
        process(chunk)
    ```

- [ ] **Step 8: EDA**
  - Skill: `exploratory-data-analysis`
  - Output: `step8-ratemyprofessor-数据分析.docx`

- [ ] **Step 9: ML Pipeline**
  - Skill: `mlops`
  - Tasks: Split, train, tune, validate, evaluate

- [ ] **Step 10: SHAP Analysis**
  - Skill: `shap`
  - Output: Model interpretation, feature importance

### Phase 3: Writing & Review ☐

- [ ] **Step 11: Report Writing**
  - Skill: `ml-paper-writing`
  - Requirements: At least 30 references
  - Output: `rate-myprofessor_report3.tex`

- [ ] **Step 12: Peer Review**
  - Skill: `peer-review`
  - Output: `rate-myprofessor_report3-review.docx`

- [ ] **Step 13: Poster**
  - Skill: `latex-posters`
  - Output: `step13-rate-myprofessor_poster3.tex` → PDF
  - Fix encoding: Use XeLaTeX

- [ ] **Step 14: Slides**
  - Skill: `scientific-slides`
  - Output: `step14-rate-myprofessor_slides3.pptx`

- [ ] **Step 15: LaTeX to PDF**
  - Commands:
    ```bash
    pdflatex report.tex
    bibtex report
    pdflatex report.tex
    pdflatex report.tex
    ```

### Phase 4: Quality Assurance ☐

- [ ] **Step 16: APA Format Check**
  - Skill: `apa-style-citation`
  - Check: References, in-text citations, statistical format
  - Output: `apa-format-check.docx`

- [ ] **Step 17: Statistical Analysis Check**
  - Skill: `statistical-analysis`
  - Output: `rate-myprofessor_report3-统计分析检查.docx`

### Phase 5: Submission ☐

- [ ] **Step 18: Cover Letter**
  - Skill: `cover-letter-writer`
  - Requirements:
    - Manuscript type
    - Why suitable for journal
    - 3 key innovations
    - Author info
    - No conflict statement
    - 3-5 reviewers

- [ ] **Step 19: Rebuttal**
  - Skill: `rebuttal`
  - Inputs: Review comments, original paper
  - Outputs:
    - `rate-myprofessor_report3-rebuttal.docx`
    - `ratemyprofessor-editor-response-letter.docx`

---

## Quick Execution Prompt

Copy and paste this to your AI agent:

```
Execute the research workflow for my project:

PROJECT: RateMyProfessor Analysis
WORKING DIRECTORY: {your_path}
DATA FILE: RMP_Moral_Processed_Professor_Moral_Tags.csv
TARGET VARIABLE: star_rating
KEYWORDS: ratemyprofessor, teaching evaluation, student evaluation of teachers, SET

Start from Step 1 and proceed through all 19 steps.
Create a todo list to track progress.
Generate all required outputs as specified in WORKFLOW.md.
```

---

## Parallel Execution Notes

For Step 2 (Literature Search), execute all database searches simultaneously:

```typescript
// Fire all in parallel
task(subagent_type="explore", run_in_background=true, prompt="Search PubMed for ratemyprofessor...")
task(subagent_type="explore", run_in_background=true, prompt="Search OpenAlex for ratemyprofessor...")
task(subagent_type="explore", run_in_background=true, prompt="Search Perplexity for ratemyprofessor...")
// Collect results when notifications arrive
```

---

## Large Data Processing Template

```python
# For files > 6GB
import pandas as pd
import dask.dataframe as dd

# Option 1: Pandas chunked
for chunk in pd.read_csv('large_file.csv', chunksize=100000):
    # Process each chunk
    processed = process_chunk(chunk)
    processed.to_csv('output.csv', mode='a', header=False)

# Option 2: Dask
ddf = dd.read_csv('large_file.csv')
result = ddf.groupby('column').mean().compute()

# Option 3: Polars (faster)
import polars as pl
df = pl.scan_csv('large_file.csv')
result = df.filter(pl.col('star_rating') > 3).collect()
```

---

## LaTeX Compilation Guide

### Standard Compilation
```bash
pdflatex report.tex
bibtex report
pdflatex report.tex
pdflatex report.tex
```

### For Chinese Characters
```bash
xelatex report.tex
bibtex report
xelatex report.tex
xelatex report.tex
```

### Required Packages for Chinese
```latex
\usepackage{ctex}
\usepackage{fontspec}
```
