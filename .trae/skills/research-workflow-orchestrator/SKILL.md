# Research Workflow Orchestrator

A comprehensive skill that orchestrates the full academic research pipeline from ideation to publication.

## Overview

This skill provides a structured 19-step workflow for conducting academic research with AI assistance. It automatically coordinates multiple sub-skills for each phase of research.

## Configuration Parameters

Before starting, configure these parameters in your project:

```yaml
# PROJECT CONFIGURATION
project:
  name: "RateMyProfessor Analysis"
  working_directory: "path/to/your/project"
  data_file: "your_data.csv"
  target_variable: "star_rating"
  
# KEYWORDS FOR SEARCH
keywords:
  primary: "ratemyprofessor"
  secondary: ["teaching evaluation", "student evaluation of teachers", "SET"]
  
# OUTPUT FILES
outputs:
  literature_file: "literature.xlsx"
  report_file: "report.tex"
  poster_file: "poster.tex"
  slides_file: "slides.pptx"
```

## Workflow Steps

### Phase 1: Research Planning (Steps 1-5)

---

#### Step 1: Research Ideation

**Skill:** `research-ideation` (AI-Research-SKILLs-main/21-research-ideation)

**Task:**
```
Using the research-ideation skill, generate research ideas based on:
- Primary keyword: {keywords.primary}
- Secondary keywords: {keywords.secondary}
- Dataset: {project.data_file}

Output: List of publication ideas with target journals
```

**Expected Output:** 
- Research questions
- Potential contribution angles
- Target journal recommendations

---

#### Step 2: Literature Search

**Skills:** All database skills in `literature-search-skills-databases/`

**Databases to search:**
- `pubmed-database` - Medical/psychology literature
- `openalex-database` - Academic papers
- `perplexity-search` - AI-powered web search
- `pubchem-database` - Chemical data (if applicable)
- `gwas-database` - Genetic data (if applicable)
- `hmdb-database` - Metabolomics (if applicable)
- `kegg-database` - Pathway data (if applicable)

**Task:**
```
For each database skill:
1. Search for papers with "{keywords.primary}" in title
2. Search for papers with "{keywords.secondary}" as keywords
3. Collect: title, authors, year, journal, abstract, DOI, citations
4. Compile all results into: step2-literature.xlsx
```

**Parallel Execution:** Fire all database searches simultaneously using background agents.

---

#### Step 3: Literature Review

**Skill:** `lit-review`

**Task:**
```
Using lit-review skill:
1. Read step2-literature.xlsx
2. Identify themes, gaps, and trends
3. Synthesize findings into coherent narrative
4. Output: step3-literature-review.docx
```

---

#### Step 4: Hypothesis Generation

**Skill:** `hypothesis-generation` (scientific-skills)

**Task:**
```
Using hypothesis-generation skill:
1. Based on literature review findings
2. Generate testable hypotheses
3. Define variables and expected relationships
4. Output: step4-hypotheses.docx
```

---

#### Step 5: Research Grants

**Skill:** `research-grants` (scientific-skills)

**Task:**
```
Using research-grants skill:
1. Identify relevant funding agencies
2. Match project to grant opportunities
3. Draft grant proposal outline
4. Output: step5-grant-opportunities.docx
```

---

### Phase 2: Data & Analysis (Steps 6-10)

---

#### Step 6: Experiment Design & Data Collection

**Note:** This step requires human execution - cannot be automated.

**Deliverable:**
- Experimental protocol
- Data collection procedures
- Ethical considerations (IRB approval if needed)

---

#### Step 7: Data Preprocessing

**Skill:** `data-processing` (AI-Research-SKILLs-main/05-data-processing)

**Critical for Large Data (>6GB):**

```
Using data-processing skill:
1. Load data in chunks (use dask/polars for large files)
2. Handle missing values
3. Feature engineering
4. Data validation
5. Save processed data

Special considerations for large files:
- Use chunked reading: pd.read_csv(file, chunksize=100000)
- Consider parquet format for efficiency
- Profile memory usage
```

**Output:** Preprocessed dataset ready for analysis

---

#### Step 8: Exploratory Data Analysis

**Skill:** `exploratory-data-analysis` (scientific-skills)

**Task:**
```
Using EDA skill:
1. Descriptive statistics
2. Distribution analysis
3. Correlation analysis
4. Visualization generation
5. Anomaly detection
6. Output: step8-eda-report.docx
```

---

#### Step 9: Machine Learning Pipeline

**Skill:** `mlops` (AI-Research-SKILLs-main/13-mlops)

**Task:**
```
Using mlops skill for standard ML workflow:
1. Train/test split
2. Feature selection
3. Model selection (try multiple algorithms)
4. Hyperparameter tuning
5. Cross-validation
6. Model evaluation
7. Save trained model and metrics
```

---

#### Step 10: Model Interpretation with SHAP

**Skill:** `shap` (scientific-skills)

**Task:**
```
Using shap skill:
1. Generate SHAP values for trained model
2. Create summary plots
3. Feature importance analysis
4. Individual prediction explanations
5. Generate interpretation figures
```

---

### Phase 3: Writing & Review (Steps 11-15)

---

#### Step 11: Report Writing

**Skill:** `ml-paper-writing` (AI-Research-SKILLs-main/20-ml-paper-writing)

**Task:**
```
Using ml-paper-writing skill:
1. Read literature file for references
2. Structure: Abstract, Intro, Methods, Results, Discussion
3. Include at least 30 references
4. Follow target journal format
5. Output: report.tex
```

---

#### Step 12: Peer Review

**Skill:** `peer-review`

**Task:**
```
Using peer-review skill:
1. Review report.tex as if you were a journal reviewer
2. Evaluate: methodology, clarity, contribution, validity
3. Provide constructive feedback
4. Output: report-review.docx
```

---

#### Step 13: Poster Creation

**Skill:** `latex-posters` (scientific-skills)

**Task:**
```
Using latex-posters skill:
1. Extract key findings from report
2. Design visually appealing poster layout
3. Include: title, authors, methods, results, conclusions
4. Output: poster.tex → poster.pdf
```

**Note:** If PDF has encoding issues, verify:
- Font encoding (use T1 or XeLaTeX)
- Chinese characters need ctex package
- Use XeLaTeX or LuaLaTeX for best results

---

#### Step 14: Slides Creation

**Skill:** `scientific-slides` (scientific-skills)

**Task:**
```
Using scientific-slides skill:
1. Create presentation from report
2. One key point per slide
3. Include visualizations
4. Output: slides.pptx
```

---

#### Step 15: LaTeX to PDF Conversion

**Task:**
```
Compile LaTeX document:
1. Run: pdflatex report.tex
2. Run: bibtex report
3. Run: pdflatex report.tex (twice for references)
4. Alternative: Use XeLaTeX for better font support
   xelatex report.tex
```

---

### Phase 4: Quality Assurance (Steps 16-17)

---

#### Step 16: APA Format Check

**Skill:** `apa-style-citation` (apa-styles-agent-skills)

**Task:**
```
Using apa-style-citation skill, check:
1. Reference list formatting (APA 7th edition)
2. In-text citation correctness
3. Statistical reporting format (APA style)
4. Output: apa-format-check.docx with issues list
```

---

#### Step 17: Statistical Analysis Check

**Skill:** `statistical-analysis`

**Task:**
```
Using statistical-analysis skill:
1. Verify statistical test appropriateness
2. Check assumptions are met
3. Verify p-value reporting
4. Check effect sizes reported
5. Verify confidence intervals
6. Output: statistical-check.docx
```

---

### Phase 5: Submission (Steps 18-19)

---

#### Step 18: Cover Letter

**Skills:** `cover-letter-writer`

**Cover Letter Requirements:**
- Manuscript type (original/review/short communication)
- Why suitable for target journal
- 3 key innovations
- Corresponding author information
- Conflict of interest statement
- 3-5 recommended reviewers (same field, no collaboration history)

**Task:**
```
Generate cover letter incorporating:
- Paper summary
- Contribution statement
- Reviewer recommendations
Output: cover-letter.docx
```

---

#### Step 19: Rebuttal Letter

**Skill:** `rebuttal`

**Task:**
```
Using rebuttal skill:
1. Read reviewer comments (report-review.docx)
2. Address each point systematically
3. Be diplomatic but firm
4. Document all changes made
5. Output: 
   - rebuttal.docx (detailed response)
   - editor-response.docx (summary letter)
```

---

## Usage Instructions

### Quick Start

1. **Configure your project:**
   ```
   Tell the agent your:
   - Working directory
   - Data file name
   - Target variable
   - Keywords for search
   ```

2. **Run the workflow:**
   ```
   "Run the research workflow for my RateMyProfessor project"
   ```

3. **The agent will:**
   - Create a todo list tracking all 19 steps
   - Execute steps sequentially (or parallel when possible)
   - Generate all required outputs

### Parallel Execution Strategy

For Steps 2, fire all database searches simultaneously:

```typescript
// All these run in parallel
task(category="quick", load_skills=["pubmed-database"], run_in_background=true, ...)
task(category="quick", load_skills=["openalex-database"], run_in_background=true, ...)
task(category="quick", load_skills=["perplexity-search"], run_in_background=true, ...)
// etc.
```

### Large Data Handling

For datasets >6GB:
- Use chunked processing
- Consider polars instead of pandas
- Save intermediate results
- Monitor memory usage

---

## Required Skills

Ensure these skills are installed in `~/.config/opencode/skills/`:

### Writing Skills
- `ai-detect`
- `argument-audit`
- `citation-audit`
- `lit-review`
- `peer-review`
- `rebuttal`

### Database Skills
- `pubmed-database`
- `openalex-database`
- `perplexity-search`
- `gwas-database`
- `hmdb-database`
- `kegg-database`
- `pubchem-database`

### Analysis Skills
- `scientific-thinking-statistical-analysis`
- `mlops` (from AI-Research-SKILLs)
- `data-processing` (from AI-Research-SKILLs)

### Writing Skills (from AI-Research-SKILLs)
- `research-ideation` (21-research-ideation)
- `ml-paper-writing` (20-ml-paper-writing)

---

## Troubleshooting

### LaTeX Encoding Issues
```
Use XeLaTeX instead of pdfLaTeX:
xelatex report.tex
```

### Large File Processing
```python
# Use chunked reading
import pandas as pd
for chunk in pd.read_csv('large_file.csv', chunksize=100000):
    process(chunk)
```

### Missing Skills
```
Check installed skills:
ls ~/.config/opencode/skills/

If missing, refer to the skills archive
```

---

## Example Invocation

```
Run the research workflow with:
- Project: RateMyProfessor Analysis
- Data: RMP_Moral_Processed_Professor_Moral_Tags.csv
- Target: star_rating
- Keywords: ratemyprofessor, teaching evaluation, SET
- Working directory: /path/to/project
```

The agent will:
1. Create a comprehensive todo list
2. Execute each step with appropriate skill
3. Generate all required documents
4. Track progress and report completion
