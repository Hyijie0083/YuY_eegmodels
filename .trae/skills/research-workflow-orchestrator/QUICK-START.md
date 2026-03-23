# Research Workflow Quick Start Guide

## Method 1: Direct Skill Invocation

Simply tell the agent:

```
Use the research-workflow-orchestrator skill to run the full research pipeline for my RateMyProfessor project.

My settings:
- Working directory: /path/to/project
- Data file: RMP_Moral_Processed_Professor_Moral_Tags.csv
- Target variable: star_rating
- Keywords: ratemyprofessor, teaching evaluation, SET
```

## Method 2: Step-by-Step with Todo Tracking

### Step 1: Create Todo List

```
Create a todo list with all 19 steps of the research workflow:
1. Research Ideation
2. Literature Search (parallel)
3. Literature Review
4. Hypothesis Generation
5. Research Grants
6. Experiment Design (manual)
7. Data Preprocessing
8. EDA
9. ML Pipeline
10. SHAP Analysis
11. Report Writing
12. Peer Review
13. Poster Creation
14. Slides Creation
15. LaTeX to PDF
16. APA Format Check
17. Statistical Analysis Check
18. Cover Letter
19. Rebuttal
```

### Step 2: Execute Phase 1 (Planning)

```typescript
// Step 1: Research Ideation
skill(name="research-ideation", user_message="Generate research ideas for: ratemyprofessor, student evaluation of teachers")

// Step 2: Literature Search (PARALLEL - fire all at once)
task(subagent_type="librarian", run_in_background=true, load_skills=["pubmed-database"], 
     description="Search PubMed", 
     prompt="Search PubMed for papers with 'ratemyprofessor' in title or 'student evaluation of teachers' as keyword. Return: title, authors, year, journal, abstract, DOI, citations.")

task(subagent_type="librarian", run_in_background=true, load_skills=["openalex-database"],
     description="Search OpenAlex",
     prompt="Search OpenAlex for papers with 'ratemyprofessor' in title or 'student evaluation of teachers' as keyword. Return: title, authors, year, journal, abstract, DOI, citations.")

task(subagent_type="librarian", run_in_background=true, load_skills=["perplexity-search"],
     description="Search Perplexity",
     prompt="Search for academic papers about 'ratemyprofessor' and 'student evaluation of teachers'. Return: title, authors, year, journal, abstract, DOI, citations.")

// Wait for all searches to complete, then compile into Excel

// Step 3: Literature Review
skill(name="lit-review", user_message="Generate literature review from step2-literature.xlsx")

// Step 4: Hypothesis Generation
skill(name="hypothesis-generation", user_message="Generate hypotheses based on literature review")

// Step 5: Research Grants
skill(name="research-grants", user_message="Find grant opportunities for this research")
```

### Step 3: Execute Phase 2 (Analysis)

```python
# Step 7: Data Preprocessing (Large File)
# The agent should use chunked processing for 6GB+ files

import pandas as pd

# Chunked reading pattern
for chunk in pd.read_csv('RMP_Moral_Processed_Professor_Moral_Tags.csv', chunksize=100000):
    # Preprocess each chunk
    pass

# Step 8: EDA
skill(name="exploratory-data-analysis", ...)

# Step 9: ML Pipeline
skill(name="mlops", ...)

# Step 10: SHAP
skill(name="shap", ...)
```

### Step 4: Execute Phase 3 (Writing)

```bash
# Step 11: Report Writing
skill(name="ml-paper-writing", user_message="Write report with at least 30 references from literature.xlsx")

# Step 12: Peer Review
skill(name="peer-review", user_message="Review rate-myprofessor_report3.tex")

# Step 13: Poster
skill(name="latex-posters", ...)

# Step 14: Slides
skill(name="scientific-slides", ...)

# Step 15: Compile
pdflatex rate-myprofessor_report3.tex
bibtex rate-myprofessor_report3
pdflatex rate-myprofessor_report3.tex
```

### Step 5: Execute Phase 4 (QA)

```bash
# Step 16: APA Check
skill(name="apa-style-citation", user_message="Check APA format for the document")

# Step 17: Statistical Check
skill(name="statistical-analysis", user_message="Verify all statistical analyses in the report")
```

### Step 6: Execute Phase 5 (Submission)

```bash
# Step 18: Cover Letter
skill(name="cover-letter-writer", ...)

# Step 19: Rebuttal (if needed)
skill(name="rebuttal", user_message="Write rebuttal for reviewer comments in report-review.docx")
```

## Method 3: Single Command

Copy and paste this entire prompt:

---

**RESEARCH WORKFLOW EXECUTION PROMPT:**

```
I want to execute a complete research workflow. Here are my project details:

## Project Configuration
- **Name**: RateMyProfessor Analysis
- **Working Directory**: {INSERT_YOUR_PATH}
- **Data File**: RMP_Moral_Processed_Professor_Moral_Tags.csv (6GB+, use chunked processing)
- **Target Variable**: star_rating
- **Keywords**: ratemyprofessor, teaching evaluation, student evaluation of teachers, SET

## Required Outputs
- step2-literature.xlsx
- step3-literature-review.docx
- step4-hypotheses.docx
- step5-grants.docx
- step8-eda.docx
- report.tex (with 30+ references)
- report-review.docx
- poster.tex/pdf
- slides.pptx
- apa-check.docx
- statistical-check.docx
- cover-letter.docx

## Execution Instructions

1. Create a todo list tracking all 19 steps
2. Execute Phase 1 (Steps 1-5): Planning
   - Use research-ideation skill
   - Fire all database searches in PARALLEL (PubMed, OpenAlex, Perplexity)
   - Compile literature into Excel
   - Generate lit review, hypotheses, grant opportunities
3. Execute Phase 2 (Steps 6-10): Analysis
   - Note: Step 6 is manual (experiment design)
   - Preprocess large data with chunking
   - Run EDA, ML pipeline, SHAP analysis
4. Execute Phase 3 (Steps 11-15): Writing
   - Write report with 30+ references
   - Peer review
   - Create poster and slides
   - Compile LaTeX to PDF
5. Execute Phase 4 (Steps 16-17): QA
   - APA format check
   - Statistical analysis check
6. Execute Phase 5 (Steps 18-19): Submission
   - Cover letter
   - Rebuttal preparation (for future use)

Begin with Step 1 and proceed through each step, marking todos as complete.
Report progress after each major phase.
```

---

## Customizing for Your Project

Replace these values in the prompt above:
- `{INSERT_YOUR_PATH}` → Your actual working directory
- Data file name → Your data file
- Target variable → Your prediction target
- Keywords → Your research keywords

## Parallel Execution Tips

For maximum efficiency:
- Step 2 (literature search): Fire ALL database searches simultaneously
- Let background agents complete before moving to dependent steps
- Check `background_output(task_id="...")` for results

## Large Data Handling

For files >6GB:
```python
# Chunked reading
for chunk in pd.read_csv('file.csv', chunksize=100000):
    process(chunk)

# Or use Dask
import dask.dataframe as dd
ddf = dd.read_csv('file.csv')
result = ddf.groupby('column').mean().compute()
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| PDF encoding issues | Use `xelatex` instead of `pdflatex` |
| Missing skill | Check `ls ~/.config/opencode/skills/` |
| Large file memory | Use chunked processing or Dask |
| LaTeX Chinese characters | Add `\usepackage{ctex}` |
