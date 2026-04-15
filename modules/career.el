;;; modules/career.el --- Career tracking and interview prep -*- lexical-binding: t; -*-
;;
;; Provides an org-mode system for tracking projects as STAR narratives,
;; preparing for interviews, and maintaining a skill inventory with evidence.
;;
;; Files live in (career/dir), defaulting to a "career/" subdirectory of
;; your registered org-dir (N:/career/ on Windows).
;;
;; First-time setup: M-x career/initialize
;; Leader prefix   : SPC C  (capital C — SPC c is taken by Code bindings)

;;; ── Path helpers ─────────────────────────────────────────────────────────────

(defun career/dir ()
  "Return the career directory path with trailing slash.
Resolves through the my/path registry (key: career-dir).
Falls back to a \"career/\" subdirectory inside org-dir."
  (file-name-as-directory
   (my/path 'career-dir
            (concat (file-name-as-directory (my/path 'org-dir "~/org/"))
                    "career"))))

(defun career/file (name)
  "Return the full path to NAME inside the career directory."
  (concat (career/dir) name))

;;; ── File templates ───────────────────────────────────────────────────────────
;; Initial content written by career/initialize when files don't exist yet.

(defconst career--projects-template
"#+TITLE: Career Projects
#+STARTUP: overview
#+TAGS: python(p) c(c) cpp(C) rf(r) dsp(d) embedded(e) hardware(h) linux(l) matlab(m) numpy(n) scipy(s) rtos(R) fpga(f) rust(u)

* Inbox
  # Quick results captured via SPC o c → cr land here.
  # Refile each bullet under the right project when you have a minute.

* RTL-SDR Spectrum Monitor                         :python:rf:dsp:numpy:scipy:hardware:
  :PROPERTIES:
  :DATE_START: 2025-09-01
  :DATE_END:   2025-12-15
  :ROLE_FIT:   defense_contractor research_lab startup
  :SKILLS:     python rf_fundamentals dsp signal_processing data_visualization rtl_sdr
  :END:

** Situation & Task
   Personal project during fall semester to understand RF and signals intelligence
   fundamentals hands-on — not from a textbook but by receiving real signals and
   building the full processing pipeline from scratch.  Chose ADS-B (1090 MHz
   aircraft transponders) because the protocol is published and unencrypted, so
   results could be verified against live FlightAware data.

** Actions
   - Streamed raw IQ samples at 2 MSPS from a $25 RTL-SDR dongle using the
     rtlsdr Python library
   - Implemented digital downconversion and a low-pass FIR filter with NumPy/SciPy
     to isolate the 1090 MHz ADS-B band
   - Built ADS-B Mode S demodulation from the protocol spec: preamble detection,
     Manchester decoding, CRC-24 validation, ICAO address extraction
   - Debugged decoding by cross-checking decoded ICAO addresses against FlightAware
   - Built a Matplotlib dashboard displaying live aircraft positions, altitudes, and
     call signs updated at ~2 Hz

** Results
   - Decoded ADS-B Mode S messages from commercial aircraft in real time
   - Reliable reception at > 200 km range with a rooftop dipole and $25 dongle
   - End-to-end latency under 500 ms from signal to displayed position
   - Tracked up to 40 simultaneous aircraft during peak traffic periods

** STAR Narrative
   #+BEGIN_QUOTE
   I built a real-time aircraft surveillance system from scratch using a $25
   software-defined radio that decoded live ADS-B transponder signals at over
   200 km range — giving me direct, end-to-end experience with a signals
   intelligence chain.

   The situation was a personal project during fall semester.  I wanted to
   understand how SIGINT actually works — receive a real signal, process it in
   software, and extract structured intelligence — without the abstraction layers
   commercial tools provide.  I chose ADS-B because it's an unencrypted published
   protocol, so I could verify my results against FlightAware.

   I wrote the entire pipeline in Python.  I streamed raw IQ samples at 2
   megasamples per second, implemented digital downconversion and a low-pass filter
   using NumPy and SciPy, then built ADS-B demodulation from the protocol spec:
   preamble detection, Manchester decoding, CRC-24 validation, ICAO address
   extraction.  The hardest part was debugging the demodulator — I had to compare
   my decoded ICAO hex addresses against live FlightAware data until the CRC logic
   was right.  Once decoding worked I built a Matplotlib dashboard showing live
   positions, altitudes, and call signs with under 500 milliseconds of latency.

   The result: reliable reception beyond 200 kilometers, tracking up to 40 aircraft
   simultaneously.  More importantly I can now read a receiver datasheet, size a
   link budget, and reason about SNR, demodulation, and protocol layers — skills I
   am ready to apply to more complex waveforms.
   #+END_QUOTE

** Relevant Roles
   - Defense contractor (L3Harris, Raytheon, Northrop Grumman) — RF/signals, SIGINT, EW
   - Research lab (MITRE, MIT Lincoln Lab, SRI) — SDR prototyping, spectrum sensing
   - Startup — embedded signal processing, radio product development

")

(defconst career--skills-template
"#+TITLE: Skills Inventory
#+STARTUP: overview

* Inbox
  # Skills captured quickly via SPC o c → cs land here.
  # Triage weekly: move each under the right category heading.

* Signal Processing & RF

** RTL-SDR / Software-Defined Radio               :rf:hardware:
   :PROPERTIES:
   :PROFICIENCY: working
   :LAST_USED:   2025-12-15
   :PROJECTS:    [[file:projects.org::*RTL-SDR Spectrum Monitor][RTL-SDR Spectrum Monitor]]
   :RESOURCES:   PySDR (pysdr.org), GNU Radio tutorials
   :END:
   IQ sample streaming, digital downconversion, FIR filter design, ADS-B decoding.

** Digital Signal Processing                       :dsp:
   :PROPERTIES:
   :PROFICIENCY: beginner
   :LAST_USED:   2025-12-15
   :PROJECTS:    [[file:projects.org::*RTL-SDR Spectrum Monitor][RTL-SDR Spectrum Monitor]]
   :RESOURCES:   DSP Guide (dspguide.com), Oppenheim & Schafer
   :END:
   FFT-based spectral analysis, FIR filter design, sampling theory, Manchester decoding.
   Needs: IIR filters, multirate DSP, matched filtering.

** RF Fundamentals                                 :rf:
   :PROPERTIES:
   :PROFICIENCY: beginner
   :LAST_USED:   2025-12-15
   :PROJECTS:    [[file:projects.org::*RTL-SDR Spectrum Monitor][RTL-SDR Spectrum Monitor]]
   :END:
   Link budgets, noise figure, antenna basics, free-space path loss, SNR.

* Programming Languages

** Python                                          :python:
   :PROPERTIES:
   :PROFICIENCY: proficient
   :LAST_USED:   2026-01-15
   :PROJECTS:    [[file:projects.org::*RTL-SDR Spectrum Monitor][RTL-SDR Spectrum Monitor]]
   :END:
   NumPy, SciPy, Matplotlib, rtlsdr, general scripting and data analysis.

** C                                               :c:
   :PROPERTIES:
   :PROFICIENCY: working
   :LAST_USED:   2025-11-01
   :PROJECTS:
   :END:
   Pointers, structs, memory management, Makefiles, embedded bare-metal patterns.

* Embedded & Hardware

** Microcontrollers                                :embedded:hardware:
   :PROPERTIES:
   :PROFICIENCY: beginner
   :LAST_USED:
   :PROJECTS:
   :END:
   GPIO, UART, SPI, I2C on STM32/Arduino-class devices.

* Tools & Frameworks

** Git                                             :tools:
   :PROPERTIES:
   :PROFICIENCY: working
   :LAST_USED:   2026-01-15
   :END:

** Linux                                           :linux:tools:
   :PROPERTIES:
   :PROFICIENCY: working
   :LAST_USED:   2026-01-15
   :END:
   Shell scripting, systemd, file permissions, networking basics.

")

(defconst career--interviews-template
"#+TITLE: Interview Log
#+STARTUP: overview

* Gaps to Fill
  # Interview questions I couldn't answer — captured via SPC o c → cq.
  # Prep a better answer here before the next interview.

* Interview Log

** TEMPLATE: [Company] — [Role] — [YYYY-MM-DD]
   :PROPERTIES:
   :COMPANY:
   :ROLE:
   :RECRUITER:
   :STAGE:      phone-screen
   :DATE:
   :END:

*** Stories Planned
    - [ ] RTL-SDR project (technical depth, challenge)
    - [ ] Add more as your project library grows

*** Questions Asked & My Answers
    | Question | How I Answered | Quality (1-5) |
    |----------+----------------+---------------|
    |          |                |               |

*** Follow-up Actions
    - [ ] Send thank-you within 24 hours

")

(defconst career--readme-template
"# Career Tracking System

A lightweight org-mode system for documenting projects as STAR narratives,
preparing for interviews, and tracking skills with concrete evidence.

---

## File Structure

| File | Purpose |
|------|---------|
| `projects.org` | One entry per project — Situation, Task, Action, Results, STAR narrative |
| `skills.org` | Skill inventory with proficiency level and links back to projects |
| `interviews.org` | Interview log, prep checklists, question gaps |
| `star-bank.org` | Searchable bank of STAR answers by question category and company type |

---

## Interactive Functions

All functions are under the `SPC C` leader prefix (capital C = Career):

| Keybinding | Command | What it does |
|------------|---------|--------------|
| `SPC C i` | `career/initialize` | Create directory and files (run once) |
| `SPC C p` | `career/new-project` | Add a new project entry with pre-filled template |
| `SPC C s` | `career/new-star-story` | Assemble a STAR story via guided prompts |
| `SPC C I` | `career/prep-for-interview` | Filter stories by role + create interview prep entry |
| `SPC C e` | `career/skill-evidence` | Show all projects demonstrating a skill |
| `SPC C r` | `career/update-result` | Log a new measurable result under an existing project |
| `SPC C c` | `org-capture` | Open capture menu |

### Capture templates (via `SPC o c` → `c`):

| Key | Template | Destination |
|-----|----------|-------------|
| `c r` | Quick Result Log | Top of `projects.org` |
| `c q` | Interview Question Gap | `interviews.org` → Gaps to Fill |
| `c s` | New Skill / Tech Used | `skills.org` → Inbox |

---

## The Habit Loop

Keep the system useful in under 5 minutes per session:

1. **After every project work session** — run `SPC C r` or `SPC o c → c r` to log
   one measurable result before the numbers fade from memory.

2. **After using a new technology** — run `SPC o c → c s` to log it to
   skills.org Inbox. Triage the Inbox weekly (move entries under the right heading,
   update PROFICIENCY and LAST_USED).

3. **Before every interview** — run `SPC C I`, enter the company name and role
   type. This opens a filtered view of your relevant STAR stories and creates a
   prep checklist in interviews.org.

---

## Writing Good STAR Narratives

**Lead with the result.** Recruiters hear hundreds of stories.
The first sentence should state the outcome.

Bad:  \"I was working on an SDR project and decided to try decoding ADS-B...\"
Good: \"I built a real-time aircraft tracking system using a $25 SDR that decoded
       live transponder signals at over 200 km range.\"

**Then explain how.** One sentence of context (Situation), one of responsibility
(Task), two or three of what you specifically did (Action), close by restating
the numbers (Result).

Target length: 60-90 seconds spoken.

---

## Tagging Convention

In `projects.org`, the `:ROLE_FIT:` property drives `career/prep-for-interview`
filtering. Use one or more of: `defense_contractor`, `startup`, `research_lab`.

Tech tags on the heading itself (`:python:rf:dsp:`) let you filter with
`org-match-sparse-tree` or org-agenda tag searches.

---

## PRIMED: Project Development Framework

PRIMED = Problem → Research → Iterate → Measure → Evaluate → Document

### Philosophy

Measure everything. Document nothing at the end that wasn't measured during.

The Measure section is the whole point. Every build session should produce at
least one logged number. If you end a session without a measurement, you have
no interview-ready evidence of what you did.

By the time you close a project, your STAR story writes itself from the Measure
log. The entries ARE your Action (what you did to get the number) and Result
(the number vs what you expected). You already wrote the story during the work.

A project with no Measure entries produced no results. Do not close it.

### Daily Habit: 4 keystrokes

```
SPC P s  —  session start   (restores context: problem, increment, last 3 measurements)
            [work on the increment]
SPC P m  —  log measurement (any time you have a number — the most important command)
SPC P e  —  session end     (mark done or blocked, set tomorrow's goal)
```
Total overhead: under 3 minutes per session.

### Connection to STAR

Measure log entries map directly to STAR structure:
- **Situation**: Problem section (why this project existed, what you were trying to do)
- **Task**: Iterate section (your specific increments and their goals)
- **Action**: Measure entries (what you did to produce each number)
- **Result**: Measure entries (the value you got vs what you expected)

`primed/close-project` assembles a STAR draft automatically from these sections.
By the time you close a project, your interview story is already written.

### Warning

The Measure section is the whole point. A project with no measurements
produced no interview-ready results. The discipline is one measurement per
session, minimum. That is all it takes.

### PRIMED Keybindings (`SPC P`)

| Keybinding | Command | When to use |
|------------|---------|-------------|
| `SPC P n` | `primed/new-project` | Starting a new project |
| `SPC P s` | `primed/session-start` | Every time you sit down to work |
| `SPC P m` | `primed/log-measurement` | Any time you have a number |
| `SPC P e` | `primed/session-end` | Every time you stop working |
| `SPC P c` | `primed/close-project` | Project complete |
| `SPC P d` | `primed/dashboard` | Weekly review |

### PRIMED Capture Templates (via `SPC o c` → `P`)

| Key | Template | Use |
|-----|----------|-----|
| `P m` | Quick Measurement | Fastest path to a logged number mid-session |
| `P i` | New Increment | Add a build step to an in-progress project |
| `P b` | Blocked Note | Log a blocker with context for future-you |
")

(defconst career--star-bank-template
"#+TITLE: STAR Story Bank
#+STARTUP: overview
#+TAGS: challenge(c) leadership(l) technical(t) failure(f) collaboration(o) impact(i)
#+TAGS: defense_contractor(d) startup(s) research_lab(r) any(a)

* Technical Depth                                  :technical:

** RTL-SDR Spectrum Monitor — ADS-B Decode         :technical:defense_contractor:research_lab:
   Target question: \"Tell me about a technical project you're proud of\"
   [[file:projects.org::*RTL-SDR Spectrum Monitor][Full entry + STAR narrative in projects.org]]

   Lead sentence: \"I built a real-time aircraft surveillance system from scratch
   using a $25 SDR that decoded live ADS-B transponder signals at over 200 km
   range.\"

* Challenge / Problem Solving                      :challenge:

* Leadership & Initiative                          :leadership:

* Failure & Learning                               :failure:

* Collaboration                                    :collaboration:

* Impact / Results                                 :impact:

")

(defconst career--primed-template
"#+TITLE: PRIMED Projects
#+STARTUP: overview
#+PROPERTY: header-args :eval never

# PRIMED = Problem → Research → Iterate → Measure → Evaluate → Document
# Each project gets exactly these six sections. Fill them in order.
# The Measure section is the whole point — log at least one number per session.

* RF Signal Classifier on Embedded Hardware              :defense_contractor:research_lab:
  :PROPERTIES:
  :SKILLS:    python tflite dsp embedded-ml signal-processing rtl-sdr
  :HOURS_EST: 40
  :STARTED:   2025-04-01
  :END:

** Problem
   Problem statement: Classify 8 modulation types from live RTL-SDR IQ samples
   in real time on a Raspberry Pi 4, achieving SIGINT-relevant accuracy and latency
   on a sub-$100 hardware stack.

   Success criteria:
   - [ ] > 85% classification accuracy at SNR >= 10 dB (RadioML 2018 test set)
   - [ ] Inference latency < 50 ms per classification frame on RPi4
   - [ ] Continuous operation > 1 hour without crash or memory leak

   Out of scope: training the model from scratch (use RadioML 2018 + pretrained CNN),
   GUI visualization, cloud inference, multi-antenna diversity.

   Why this project: defense contractor / research lab — demonstrates end-to-end embedded
   SIGINT chain (antenna → DSP → ML → classified label) on real hardware.

** Research
   Prior art:
   - DeepSig RadioML 2018 dataset (largest public RF modulation benchmark)
   - O'Shea & Hoydis (2017) CNN modulation classifier — the baseline architecture
   - TFLite int8 quantization guide (tensorflow.org/lite/performance/quantization_spec)

   Knowledge gaps:
   - TFLite int8 quantization workflow end-to-end
   - RPi4 CPU performance profiling (cProfile, time.perf_counter)
   - RTL-SDR real-time IQ streaming without frame drops at 2 MSPS

   Tools and hardware:
   - RTL-SDR dongle: $25 (already owned)
   - Raspberry Pi 4 4GB: $55 (used)
   - Python, TensorFlow/Keras (laptop training), TensorFlow Lite (RPi4 inference)
   - RadioML 2018.01a dataset: free download (~7 GB)

   Estimated time: 40 hours across 6 increments

** Iterate
   - Increment 1: Set up RadioML 2018, train baseline CNN on laptop | Expected: top-1 accuracy > 85% at 10 dB on test set | Status: DONE
   - Increment 2: Convert model to TFLite int8 | Expected: accuracy drop < 5%, model size < 2 MB | Status: DONE
   - Increment 3: Benchmark inference on RPi4 | Expected: single-frame latency < 50 ms | Status: DONE
   - Increment 4: Connect RTL-SDR, capture and preprocess live IQ frames | Expected: no dropped frames at 2 MSPS | Status: DONE
   - Increment 5: End-to-end pipeline: capture → normalize → classify → print label | Expected: working demo | Status: DONE
   - Increment 6: Stress test 1+ hour continuous operation | Expected: no crash, stable memory | Status: DONE

** Measure
   [2025-04-03] Baseline CNN accuracy at 10 dB SNR (RadioML test set): 91.2% vs 85% target — strong baseline, well above target
   [2025-04-03] Float32 model size: 2.3 MB vs no target — acceptable for RPi4; will quantize to reduce further
   [2025-04-05] TFLite int8 accuracy at 10 dB SNR: 89.7% vs 85% target — quantization cost < 1.5%, still above target
   [2025-04-05] Inference latency on RPi4 4GB (TFLite int8, single frame): 43 ms vs 50 ms target — 14% under limit
   [2025-04-08] Live RTL-SDR classification accuracy (known-modulation test signals): 84.1% vs 85% target — 1% below; real-channel noise is the culprit
   [2025-04-08] Continuous operation before crash: > 2 hours vs 1 hour target — passed, no memory leaks detected

** Evaluate
   Criterion 1 (>85% accuracy at 10 dB): YES on RadioML benchmark (89.7%); borderline on live signals (84.1%)
   Criterion 2 (<50 ms inference latency): YES — 43 ms median on RPi4 4GB
   Criterion 3 (>1 hour continuous): YES — 2+ hours confirmed without crash

   What broke or surprised me: Live signal accuracy fell 5% below benchmark. Traced to
   real-channel noise and the absence of receiver gain calibration. RadioML is synthetic;
   real channels add multipath, frequency offset, and quantization noise that the model
   hasn't seen.

   What I would do differently: Collect and label 30 minutes of field IQ recordings across
   several known-modulation signals and fine-tune the model on them. Add an SNR estimator
   to the pipeline so the classifier can report confidence bounds alongside the label.

   One-sentence result: Deployed a real-time RF modulation classifier on a Raspberry Pi 4
   achieving 89.7% accuracy and 43 ms inference latency on 8 modulation types from live
   IQ samples, running continuously for 2+ hours on a $80 hardware stack.

** Document
   - [X] GitHub README written
   - [X] STAR block written in star-bank.org (see below)
   - [X] skills.org updated (TFLite, embedded-ML, RPi4 profiling added)
   - [X] Project entry added to projects.org
   - [X] Accuracy-vs-SNR plot and latency histogram linked

   #+BEGIN_QUOTE
   STAR — Target audience: Raytheon, L3Harris, Northrop Grumman (RF/signals roles)

   I deployed a real-time RF modulation classifier on a Raspberry Pi 4 that
   identifies 8 signal types from live IQ samples at 89.7% accuracy and 43 ms
   inference latency — a full embedded SIGINT pipeline from antenna to classified
   output on an $80 hardware stack.

   The project was to prove that machine-learning-based signal classification could
   run on edge hardware with performance you could defend in a design review. I chose
   modulation classification because it is a real SIGINT primitive and RadioML 2018
   gives a published benchmark to measure against — no cherry-picking results.

   I trained a CNN on RadioML 2018, applied TFLite int8 quantization to fit the RPi4
   compute budget, then built a real-time pipeline: RTL-SDR at 2 MSPS → IQ frame
   capture → normalization → inference → label output. The bottleneck turned out to be
   the normalization step — profiling showed it at 24 ms per frame. Vectorizing it with
   NumPy cut that to 8 ms and brought total latency from 67 ms to 43 ms.

   Result: 89.7% benchmark accuracy, 43 ms latency (14% under target), 2+ hours
   continuous operation confirmed. On live signals accuracy dropped to 84.1% — one
   percent below target — which I traced to real-channel noise and the lack of receiver
   calibration. That gap tells you exactly what the next version needs.
   #+END_QUOTE

* NEW PROJECT TEMPLATE                                   :defense_contractor:
  # Copy this section to start a new project. Delete this heading when done.
  :PROPERTIES:
  :SKILLS:
  :HOURS_EST:
  :STARTED:
  :END:

** Problem
   Problem statement: [What does this system need to do? 1-2 sentences.]

   Success criteria:
   - [ ] [Criterion 1 — must be numeric: e.g., > X% accuracy, < Y ms latency]
   - [ ] [Criterion 2 — must be numeric]
   - [ ] [Criterion 3 — must be numeric]

   Out of scope: [What you are explicitly NOT building. Be specific.]

   Why this project: [Which skills it demonstrates, which role types it targets.]

** Research
   Prior art:
   - [Paper, repo, or tool you're building on]

   Knowledge gaps:
   - [What you need to learn before starting]

   Tools and hardware:
   - [Item: $cost]

   Estimated time: [N] hours

** Iterate
   - Increment 1: [Goal — one sentence] | Expected: [Observable output when done] | Status: TODO

** Measure
   # Format: [YYYY-MM-DD] [Metric name]: [measured value] vs [expected value] — [one-line interpretation]
   # Log at least one entry per build session. This is the whole point.

** Evaluate
   # Fill in with primed/close-project when all increments are DONE.
   # primed/close-project will refuse to run if this section is still empty
   # and the Problem section still has unfilled success criteria.

** Document
   - [ ] GitHub README written
   - [ ] STAR block written in star-bank.org
   - [ ] skills.org updated with new proficiency evidence
   - [ ] Project entry added to projects.org
   - [ ] Photos, plots, or recordings linked

")

;;; ── Initializer ──────────────────────────────────────────────────────────────

(defun career/initialize ()
  "Create the career directory and org files if they do not exist.
Safe to run multiple times — existing files are never overwritten."
  (interactive)
  (make-directory (career/dir) t)
  (career--init-file "projects.org"   career--projects-template)
  (career--init-file "skills.org"     career--skills-template)
  (career--init-file "interviews.org" career--interviews-template)
  (career--init-file "star-bank.org"  career--star-bank-template)
  (career--init-file "primed.org"     career--primed-template)
  (career--init-file "README.md"      career--readme-template)
  (message "Career directory ready at %s" (career/dir)))

(defun career/rewrite-readme ()
  "Overwrite README.md with the current career--readme-template.
Use this to update an existing README when the template has changed.
career/initialize never overwrites existing files, so this is the
only way to sync the on-disk README after an update."
  (interactive)
  (with-temp-file (career/file "README.md")
    (insert career--readme-template))
  (message "README.md updated at %s" (career/file "README.md")))

(defun career--init-file (name content)
  "Write CONTENT to NAME in the career directory if the file does not exist."
  (let ((path (career/file name)))
    (unless (file-exists-p path)
      (with-temp-file path
        (insert content)))))

;;; ── Interactive functions ────────────────────────────────────────────────────

(defun career/new-project (name tech-stack summary)
  "Add a new project entry to projects.org with a pre-filled template.
Prompts for NAME (project title), TECH-STACK (comma-separated tags),
and SUMMARY (one-line description of what you built).
Opens the buffer at the new heading so you can start filling it in."
  (interactive
   (list (read-string "Project name: ")
         (read-string "Tech stack (comma-separated, e.g. python,rf,dsp): ")
         (read-string "One-line summary (what you built): ")))
  (career/initialize)
  (let* ((tags (mapconcat #'string-trim (split-string tech-stack "," t " ") ":"))
         (tag-string (if (string-empty-p tags) "" (concat "  :" tags ":")))
         (date (format-time-string "%Y-%m-%d"))
         (skills (replace-regexp-in-string "," " " tech-stack))
         (entry (concat
                 "\n* " name tag-string "\n"
                 "  :PROPERTIES:\n"
                 "  :DATE_START: " date "\n"
                 "  :DATE_END:\n"
                 "  :ROLE_FIT:   defense_contractor research_lab startup\n"
                 "  :SKILLS:     " skills "\n"
                 "  :END:\n\n"
                 "  Summary: " summary "\n\n"
                 "** Situation & Task\n"
                 "   [Context: why did this project exist? What were you trying to accomplish?]\n\n"
                 "** Actions\n"
                 "   - [What specifically did YOU do? Include tools, algorithms, key decisions.]\n"
                 "   - [What was the hardest part and how did you solve it?]\n\n"
                 "** Results\n"
                 "   - [Quantify: X% improvement, Y ms latency, Z units processed]\n"
                 "   - [What worked? What surprised you?]\n\n"
                 "** STAR Narrative\n"
                 "   #+BEGIN_QUOTE\n"
                 "   [Lead with result: \"I built X that achieved Y.\"]\n"
                 "   [Situation: one sentence — context, why this existed]\n"
                 "   [Action: 2-3 sentences — what you built, key decisions, hardest problem]\n"
                 "   [Result: restate numbers + what it taught you]\n"
                 "   #+END_QUOTE\n\n"
                 "** Relevant Roles\n"
                 "   - [Company type — specific role area]\n")))
    (find-file (career/file "projects.org"))
    (goto-char (point-max))
    (insert entry)
    (save-buffer)
    (org-previous-visible-heading 1)
    (message "Project \"%s\" added to projects.org — fill in the template sections." name)))

(defun career/new-star-story ()
  "Prompt through Situation, Task, Action, Result and save to star-bank.org.
Also asks for the question category and target company type, then
files the assembled narrative under the right category heading."
  (interactive)
  (career/initialize)
  (let* ((title    (read-string "Story title (short descriptive name): "))
         (question (completing-read "Question category: "
                                    '("technical" "challenge" "leadership"
                                      "failure" "collaboration" "impact")
                                    nil t))
         (audience (completing-read "Target company type: "
                                    '("defense_contractor" "startup"
                                      "research_lab" "any")
                                    nil t))
         (result   (read-string "Result FIRST — quantify the outcome: "))
         (sit      (read-string "Situation — context in one sentence: "))
         (task     (read-string "Task — your specific responsibility: "))
         (action   (read-string "Action — what YOU did (tools, decisions, hardest part): "))
         (tags     (concat ":" question ":" audience ":"))
         (entry    (concat "\n** " title "  " tags "\n"
                           "   Target question: \"" question "\"\n\n"
                           "   #+BEGIN_QUOTE\n"
                           "   " result "\n\n"
                           "   The situation: " sit "\n\n"
                           "   " action "\n\n"
                           "   Result: " result "\n"
                           "   #+END_QUOTE\n")))
    (find-file (career/file "star-bank.org"))
    (goto-char (point-min))
    ;; Find the right category heading and insert there
    (if (re-search-forward
         (concat "^\\* " (capitalize question)) nil t)
        (org-end-of-subtree t)
      (goto-char (point-max)))
    (insert entry)
    (save-buffer)
    (message "STAR story \"%s\" saved to star-bank.org." title)))

(defun career/prep-for-interview (company role-type)
  "Prepare for an interview at COMPANY for a role of ROLE-TYPE.
Opens projects.org filtered to stories tagged for that role type,
and creates a prep checklist entry in interviews.org."
  (interactive
   (list (read-string "Company name: ")
         (completing-read "Role type: "
                          '("defense_contractor" "startup" "research_lab")
                          nil t)))
  (career/initialize)
  (let* ((date  (format-time-string "%Y-%m-%d"))
         (entry (concat "\n** " company " — " role-type " — " date "\n"
                        "   :PROPERTIES:\n"
                        "   :COMPANY:  " company "\n"
                        "   :ROLE:     " role-type "\n"
                        "   :STAGE:    phone-screen\n"
                        "   :DATE:     " date "\n"
                        "   :END:\n\n"
                        "*** Stories to Use\n"
                        "    Open [[file:projects.org][projects.org]] and [[file:star-bank.org][star-bank.org]] — "
                        "pick 3-4 stories tagged :" role-type ":\n"
                        "    - [ ] Story 1:\n"
                        "    - [ ] Story 2:\n"
                        "    - [ ] Story 3:\n\n"
                        "*** Skills to Refresh\n"
                        "    Check [[file:skills.org][skills.org]] LAST_USED dates — refresh anything > 60 days old.\n"
                        "    - [ ] \n\n"
                        "*** Questions to Prepare\n"
                        "    - [ ] Why this company specifically?\n"
                        "    - [ ] What do you want to work on here?\n"
                        "    - [ ] Questions to ask them:\n\n"
                        "*** Follow-up Actions\n"
                        "    - [ ] Send thank-you email within 24 hours\n")))
    ;; Show matching stories in projects.org
    (find-file (career/file "projects.org"))
    (org-match-sparse-tree nil (concat "ROLE_FIT={" role-type "}"))
    ;; Create the prep entry in interviews.org
    (find-file (career/file "interviews.org"))
    (goto-char (point-max))
    (insert entry)
    (save-buffer)
    (message "Prep entry created for %s. stories are filtered in projects.org." company)))

(defun career/skill-evidence (skill)
  "Show all projects in projects.org that demonstrate SKILL.
Runs org-occur across projects.org searching for the skill string."
  (interactive (list (read-string "Skill to find evidence for (e.g. python, dsp): ")))
  (career/initialize)
  (find-file (career/file "projects.org"))
  (org-occur (regexp-quote skill))
  (message "Showing entries mentioning \"%s\" in projects.org." skill))

(defun career/update-result (result-text)
  "Append RESULT-TEXT as a new bullet to a project's Results section.
Opens projects.org, prompts you to navigate to a project heading
with org-goto, then inserts the result under the Results subheading."
  (interactive
   (list (read-string "New result (be specific — include numbers): ")))
  (career/initialize)
  (find-file (career/file "projects.org"))
  (org-goto)
  ;; Search forward within this subtree for the Results heading
  (let* ((subtree-end (save-excursion (org-end-of-subtree t) (point)))
         (found (re-search-forward "^\\*\\* Results" subtree-end t)))
    (if found
        (progn
          (org-end-of-subtree t)
          (unless (bolp) (newline))
          (insert (concat "   - " result-text "\n"))
          (save-buffer)
          (message "Result logged under Results section."))
      (message "No '** Results' section found here — add one manually or navigate to the right project."))))

;;; ── PRIMED helpers ───────────────────────────────────────────────────────────
;; Private functions used by the primed/* interactive commands.
;; All operate on primed.org via find-file-noselect to avoid disturbing the
;; user's current buffer or window layout.

(defun primed--project-names ()
  "Return a list of level-1 heading titles in primed.org.
Excludes the NEW PROJECT TEMPLATE stub."
  (let ((file (career/file "primed.org")))
    (when (file-exists-p file)
      (with-current-buffer (find-file-noselect file)
        (org-map-entries
         (lambda () (org-get-heading t t t t))
         "LEVEL=1")))))

(defun primed--read-project (&optional prompt)
  "completing-read a project name from primed.org level-1 headings.
PROMPT defaults to \"Project: \".
If no projects exist, offers to run primed/new-project and signals an error."
  (let ((names (seq-remove
                (lambda (n) (string-match-p "NEW PROJECT TEMPLATE" n))
                (primed--project-names))))
    (if names
        (completing-read (or prompt "Project: ") names nil t)
      (when (y-or-n-p "No PRIMED projects found. Create one now? ")
        (call-interactively #'primed/new-project))
      (user-error "No PRIMED projects found — run M-x primed/new-project first"))))

(defun primed--section-text (project section)
  "Return the body text of SECTION under PROJECT in primed.org.
SECTION is a level-2 heading name (e.g., \"Measure\", \"Problem\").
Returns the text between that heading and the next ** heading, or nil."
  (let ((file (career/file "primed.org")))
    (when (file-exists-p file)
      (with-current-buffer (find-file-noselect file)
        (save-excursion
          (goto-char (point-min))
          (when (re-search-forward
                 (concat "^\\* " (regexp-quote project)) nil t)
            (let ((proj-end (save-excursion (org-end-of-subtree t) (point))))
              (when (re-search-forward
                     (concat "^\\*\\* " (regexp-quote section)) proj-end t)
                (forward-line 1)
                (let* ((start (point))
                       (end (progn
                              (if (re-search-forward "^\\*\\*" proj-end t)
                                  (match-beginning 0)
                                proj-end)
                              (point))))
                  (string-trim
                   (buffer-substring-no-properties start end)))))))))))

(defun primed--insert-in-section (project section text)
  "Append TEXT at the end of SECTION under PROJECT in primed.org.
TEXT should already include a trailing newline.  Saves the buffer."
  (let ((file (career/file "primed.org")))
    (unless (file-exists-p file)
      (user-error "primed.org not found — run M-x career/initialize first"))
    (with-current-buffer (find-file-noselect file)
      (save-excursion
        (goto-char (point-min))
        (unless (re-search-forward
                 (concat "^\\* " (regexp-quote project)) nil t)
          (user-error "Project \"%s\" not found in primed.org" project))
        (let ((proj-end (save-excursion (org-end-of-subtree t) (point))))
          (unless (re-search-forward
                   (concat "^\\*\\* " (regexp-quote section)) proj-end t)
            (user-error "Section \"%s\" not found in project \"%s\"" section project))
          (org-end-of-subtree t)
          (unless (bolp) (newline))
          (insert text)))
      (save-buffer))))

(defun primed--current-increment (iterate-text)
  "Return the first TODO or IN-PROGRESS line from ITERATE-TEXT string.
Returns nil if none found."
  (when iterate-text
    (with-temp-buffer
      (insert iterate-text)
      (goto-char (point-min))
      (when (re-search-forward ".*\\(TODO\\|IN-PROGRESS\\).*" nil t)
        (string-trim (match-string 0))))))

(defun primed--last-n-lines (text n)
  "Return the last N non-blank lines of TEXT as a single string."
  (when text
    (let* ((lines (split-string text "\n"))
           (non-blank (seq-filter (lambda (l) (not (string-blank-p l))) lines))
           (tail (last non-blank n)))
      (string-join tail "\n"))))

(defun primed--capture-goto-measure ()
  "Navigate to the end of the Measure section of a selected project.
Used as the file+function target for the Pm org-capture template."
  (let ((project (primed--read-project "Log measurement for project: ")))
    (goto-char (point-min))
    (re-search-forward (concat "^\\* " (regexp-quote project)) nil t)
    (let ((proj-end (save-excursion (org-end-of-subtree t) (point))))
      (re-search-forward "^\\*\\* Measure" proj-end t)
      (org-end-of-subtree t)
      (unless (bolp) (newline)))))

(defun primed--capture-goto-iterate ()
  "Navigate to the end of the Iterate section of a selected project.
Used as the file+function target for the Pi and Pb org-capture templates."
  (let ((project (primed--read-project "Add to project: ")))
    (goto-char (point-min))
    (re-search-forward (concat "^\\* " (regexp-quote project)) nil t)
    (let ((proj-end (save-excursion (org-end-of-subtree t) (point))))
      (re-search-forward "^\\*\\* Iterate" proj-end t)
      (org-end-of-subtree t)
      (unless (bolp) (newline)))))

;;; ── PRIMED interactive functions ─────────────────────────────────────────────

(defun primed/new-project (name role-type skills hours)
  "Create a new PRIMED project entry in primed.org.
Prompts for NAME, ROLE-TYPE (completing-read), primary SKILLS
(comma-separated), and estimated HOURS.
Appends the full 6-section template and opens the buffer at the new entry."
  (interactive
   (list (read-string "Project name: ")
         (completing-read "Target role type: "
                          '("defense_contractor" "startup" "research_lab" "any")
                          nil t)
         (read-string "Primary skills (comma-separated): ")
         (read-string "Estimated hours: ")))
  (career/initialize)
  (let* ((date (format-time-string "%Y-%m-%d"))
         (entry
          (concat
           "\n* " name "  :" role-type ":\n"
           "  :PROPERTIES:\n"
           "  :SKILLS:    " skills "\n"
           "  :HOURS_EST: " hours "\n"
           "  :STARTED:   " date "\n"
           "  :END:\n\n"
           "** Problem\n"
           "   Problem statement: [What does this system need to do? 1-2 sentences.]\n\n"
           "   Success criteria:\n"
           "   - [ ] [Criterion 1 — must be numeric: e.g., > X% accuracy, < Y ms latency]\n"
           "   - [ ] [Criterion 2 — must be numeric]\n"
           "   - [ ] [Criterion 3 — must be numeric]\n\n"
           "   Out of scope: [What you are NOT building. Be specific.]\n\n"
           "   Why this project: " role-type " — demonstrates " skills "\n\n"
           "** Research\n"
           "   Prior art:\n   - \n\n"
           "   Knowledge gaps:\n   - \n\n"
           "   Tools and hardware:\n   - \n\n"
           "   Estimated time: " hours " hours\n\n"
           "** Iterate\n"
           "   - Increment 1: [Goal — one sentence] | Expected: [Observable output] | Status: TODO\n"
           "     SCHEDULED: " date "\n\n"
           "** Measure\n"
           "   # Format: [DATE] [Metric]: [value] vs [expected] — [interpretation]\n"
           "   # Log at least one entry per build session.\n\n"
           "** Evaluate\n"
           "   # Fill in with primed/close-project when all increments are DONE.\n\n"
           "** Document\n"
           "   - [ ] GitHub README written\n"
           "   - [ ] STAR block written in star-bank.org\n"
           "   - [ ] skills.org updated with new proficiency evidence\n"
           "   - [ ] Project entry added to projects.org\n"
           "   - [ ] Photos, plots, or recordings linked\n")))
    (find-file (career/file "primed.org"))
    (goto-char (point-max))
    (insert entry)
    (save-buffer)
    (org-previous-visible-heading 1)
    (message "PRIMED project \"%s\" created — fill in Problem and Research first." name)))

(defun primed/log-measurement (project metric value expected note)
  "Log a measurement entry to the Measure section of PROJECT in primed.org.
Prompts for PROJECT (completing-read), METRIC name, measured VALUE,
EXPECTED value, and a one-line NOTE.
Appends a timestamped entry and saves.  Never opens a new buffer."
  (interactive
   (list (primed--read-project "Log measurement for project: ")
         (read-string "Metric: ")
         (read-string "Measured value: ")
         (read-string "Expected value: ")
         (read-string "One-line interpretation: ")))
  (let* ((date  (format-time-string "%Y-%m-%d"))
         (entry (format "   [%s] %s: %s vs %s — %s\n" date metric value expected note)))
    (primed--insert-in-section project "Measure" entry)
    (message "[%s] %s: %s vs %s logged." date metric value expected)))

(defun primed/session-start ()
  "Restore context for a PRIMED project work session.
Shows the project's Problem statement, the current increment goal,
and the last 3 measurement entries in a read-only buffer."
  (interactive)
  (let* ((project  (primed--read-project "Start session for project: "))
         (problem  (primed--section-text project "Problem"))
         (iterate  (primed--section-text project "Iterate"))
         (measure  (primed--section-text project "Measure"))
         (inc      (or (primed--current-increment iterate)
                       "No active increment — add one with SPC P n or SPC o c P i"))
         (last3    (or (primed--last-n-lines measure 3)
                       "No measurements yet — log one with SPC P m"))
         (prob-preview (mapconcat #'identity
                                  (seq-take (split-string (or problem "") "\n") 6)
                                  "\n"))
         (buf-name (format "*PRIMED: %s*" project)))
    (with-current-buffer (get-buffer-create buf-name)
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (format "\n  PROJECT: %s\n" project))
        (insert (format "  Session: %s\n" (format-time-string "%Y-%m-%d %H:%M")))
        (insert  "  ══════════════════════════════════════════════════════\n\n")
        (insert  "  PROBLEM\n")
        (insert  "  ───────\n")
        (insert (replace-regexp-in-string "^" "  " prob-preview))
        (insert  "\n\n")
        (insert  "  TODAY'S INCREMENT\n")
        (insert  "  ─────────────────\n")
        (insert (format "  %s\n\n" inc))
        (insert  "  LAST 3 MEASUREMENTS\n")
        (insert  "  ────────────────────\n")
        (insert (replace-regexp-in-string "^" "  " last3))
        (insert  "\n\n")
        (insert  "  Press q to close.\n"))
      (special-mode))
    (pop-to-buffer buf-name)))

(defun primed/session-end ()
  "Close out a PRIMED work session.
Prompts whether the current increment was completed, logs a measurement
if done, or records a blocker if not.  Then asks for tomorrow's increment."
  (interactive)
  (let* ((project (primed--read-project "End session for project: "))
         (done-p  (y-or-n-p (format "[%s] Did you complete today's increment? " project))))
    (if done-p
        (progn
          ;; Mark first TODO in Iterate as DONE
          (with-current-buffer (find-file-noselect (career/file "primed.org"))
            (save-excursion
              (goto-char (point-min))
              (when (re-search-forward
                     (concat "^\\* " (regexp-quote project)) nil t)
                (let ((proj-end (save-excursion (org-end-of-subtree t) (point))))
                  (when (re-search-forward "^\\*\\* Iterate" proj-end t)
                    (let ((sect-end (save-excursion
                                      (if (re-search-forward "^\\*\\*" proj-end t)
                                          (match-beginning 0)
                                        proj-end))))
                      (when (re-search-forward "| Status: TODO" sect-end t)
                        (replace-match "| Status: DONE")))))))
            (save-buffer))
          (message "Increment marked DONE.")
          ;; Require at least one measurement
          (message "Good — now log today's result.")
          (call-interactively #'primed/log-measurement))
      ;; Not done — record blocker
      (let ((blocker (read-string "Blocker or updated description: ")))
        (primed--insert-in-section
         project "Iterate"
         (format "   BLOCKED [%s]: %s\n"
                 (format-time-string "%Y-%m-%d") blocker))))
    ;; Always ask for next increment
    (let ((next (read-string "Tomorrow's increment goal (one sentence): ")))
      (primed--insert-in-section
       project "Iterate"
       (format "   - Next: %s | Expected: [define before sitting down] | Status: TODO\n" next)))
    (message "Session closed for \"%s\". See you next time." project)))

(defun primed/close-project ()
  "Fill in the Evaluate section for a completed PRIMED project.
Refuses to run if success criteria have not been defined (guard check).
Generates a STAR block and appends it to star-bank.org.
Opens the Document section checklist when done."
  (interactive)
  (let* ((project  (primed--read-project "Close project: "))
         (prob-text (primed--section-text project "Problem")))
    ;; ── Guard: success criteria must be filled in ──────────────────────────
    (when (or (null prob-text)
              (string-match-p "must be numeric" prob-text)
              (string-match-p "\\[Criterion 1" prob-text)
              (< (length (seq-filter
                          (lambda (l) (not (string-blank-p l)))
                          (split-string prob-text "\n")))
                 3))
      (user-error
       "Project \"%s\": success criteria not defined. Fill in the Problem section first."
       project))
    ;; ── Interactive Evaluate prompts ───────────────────────────────────────
    (let* ((criteria (read-string "Did you meet each success criterion? (be specific, one per line): "))
           (broke    (read-string "What broke or surprised you: "))
           (diff     (read-string "What you would do differently: "))
           (result   (read-string "One-sentence result (lead with what you built and what it did): "))
           (measure  (primed--section-text project "Measure"))
           (last5    (primed--last-n-lines (or measure "") 5))
           (eval-text
            (concat
             "   Criteria: " criteria "\n"
             "   What broke: " broke "\n"
             "   Do differently: " diff "\n"
             "   Result: " result "\n"))
           (star-block
            (concat
             "\n** " project " — PRIMED Close"
             "  :technical:defense_contractor:\n"
             "   Target question: \"Tell me about a technical project you're proud of\"\n\n"
             "   #+BEGIN_QUOTE\n"
             "   " result "\n\n"
             "   Situation: " (or (car (split-string (or prob-text "") "\n")) "[see Problem section]") "\n\n"
             "   Action / Measurements:\n"
             (replace-regexp-in-string "^" "   " last5) "\n\n"
             "   What broke: " broke "\n"
             "   What I'd do differently: " diff "\n"
             "   #+END_QUOTE\n")))
      ;; Write Evaluate section
      (primed--insert-in-section project "Evaluate" eval-text)
      ;; Append STAR to star-bank.org under Technical Depth
      (with-current-buffer (find-file-noselect (career/file "star-bank.org"))
        (goto-char (point-min))
        (if (re-search-forward "^\\* Technical Depth" nil t)
            (org-end-of-subtree t)
          (goto-char (point-max)))
        (unless (bolp) (newline))
        (insert star-block)
        (save-buffer))
      ;; Open Document checklist
      (find-file (career/file "primed.org"))
      (goto-char (point-min))
      (re-search-forward (concat "^\\* " (regexp-quote project)) nil t)
      (re-search-forward "^\\*\\* Document" nil t)
      (org-show-subtree)
      (message "Evaluate written. STAR appended to star-bank.org. Check off the Document list."))))

(defun primed/dashboard ()
  "Show a PRIMED project dashboard in a split window.
Left: summary of active and recently closed projects.
Right: primed.org in overview mode."
  (interactive)
  (career/initialize)
  (let* ((names   (seq-remove
                   (lambda (n) (string-match-p "NEW PROJECT TEMPLATE" n))
                   (primed--project-names)))
         (today   (float-time))
         (30-days (* 30 86400))
         active closed)
    ;; Classify projects by whether Evaluate is filled
    (dolist (proj names)
      (let* ((eval-text (primed--section-text proj "Evaluate"))
             (eval-lines (when eval-text
                           (seq-filter (lambda (l) (not (string-blank-p l)))
                                       (split-string eval-text "\n"))))
             (filled-p (and eval-lines (>= (length eval-lines) 4))))
        (if filled-p
            (push (cons proj (primed--last-n-lines eval-text 1)) closed)
          (let* ((iter  (primed--section-text proj "Iterate"))
                 (inc   (or (primed--current-increment iter) "No active increment"))
                 (meas  (primed--section-text proj "Measure"))
                 (last1 (primed--last-n-lines (or meas "") 1)))
            (push (list proj inc last1) active)))))
    ;; Build display
    (delete-other-windows)
    (let ((right (split-window-right)))
      ;; Right: primed.org
      (with-selected-window right
        (find-file (career/file "primed.org"))
        (org-overview))
      ;; Left: dashboard buffer
      (with-current-buffer (get-buffer-create "*PRIMED Dashboard*")
        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert (format "\n  PRIMED Dashboard — %s\n" (format-time-string "%Y-%m-%d")))
          (insert  "  ══════════════════════════════════════\n\n")
          (if active
              (progn
                (insert "  ACTIVE\n  ──────\n")
                (dolist (p (nreverse active))
                  (insert (format "  ▶ %s\n" (car p)))
                  (insert (format "    Increment: %s\n" (cadr p)))
                  (when (caddr p)
                    (insert (format "    Last meas:  %s\n" (caddr p))))
                  (insert "\n")))
            (insert "  ACTIVE\n  ──────\n  (no active projects)\n\n"))
          (if closed
              (progn
                (insert "  CLOSED\n  ──────\n")
                (dolist (p (nreverse closed))
                  (insert (format "  ✓ %s\n" (car p)))
                  (when (cdr p)
                    (insert (format "    \"%s\"\n" (cdr p))))
                  (insert "\n")))
            (insert "  CLOSED\n  ──────\n  (none yet)\n\n"))
          (insert "  Press q to close.\n"))
        (special-mode)
        (pop-to-buffer (current-buffer))))))

;;; ── Bill of Materials ────────────────────────────────────────────────────────

(defconst career--bom-header
  "| Part No. | Description | Manufacturer | Package | Designator | Qty | Unit Price | Real Price | URL |
|----------+-------------+--------------+---------+------------+-----+------------+------------+-----|
|          |             |              |         |            |   1 |       0.00 |       0.00 |     |
#+TBLFM: $8=$6*$7"
  "Skeleton org table for a bill of materials.
Columns: Part No., Description, Manufacturer, Package, Designator,
         Qty, Unit Price, Real Price (=Qty×Unit), URL.
#+TBLFM recalculates Real Price automatically (C-c C-c on the TBLFM line).")

(defun career/new-bom (name)
  "Insert a Bill of Materials org table headed by NAME at point.
If the buffer is visiting a file, the table is inserted there.
Otherwise a temporary *BOM* buffer is opened."
  (interactive "sBOM name (e.g. project or assembly): ")
  (let ((insert-bom
         (lambda ()
           (insert (format "** BOM — %s\n" name))
           (insert career--bom-header)
           (insert "\n"))))
    (if buffer-file-name
        (progn
          (funcall insert-bom)
          (message "BOM inserted — press C-c C-c on the #+TBLFM line to recalculate."))
      (let ((buf (get-buffer-create (format "*BOM: %s*" name))))
        (switch-to-buffer buf)
        (org-mode)
        (funcall insert-bom)
        (goto-char (point-min))
        (message "BOM in temp buffer — C-c C-c on #+TBLFM to recalculate.")))))

;;; ── Capture templates + keybindings ─────────────────────────────────────────
;; Both are deferred to elpaca-after-init-hook, which fires after ALL packages
;; are fully loaded and configured.  This avoids two race conditions:
;;
;;   1. Keybinding race: career.el (alphabetically "c") registers its
;;      with-eval-after-load 'meow callback before keybindings.el ("k") does.
;;      When meow loads, career's callback would fire first — before
;;      keybindings.el has run `(define-key meow-normal-state-keymap "SPC" nil)`
;;      — so SPC is still a terminal key and "SPC C i" fails.
;;
;;   2. Capture template race: org-capture-templates is defined in org-capture.el,
;;      not org.el.  A with-eval-after-load 'org callback fires before org-capture
;;      is loaded, so the variable is void and add-to-list errors out.
;;
;; By elpaca-after-init-hook: meow SPC is cleared, my/leader is defined,
;; org-config.el's setq has run, and org-capture-templates exists.

(add-hook 'elpaca-after-init-hook
          (lambda ()
            ;; ── Capture templates ───────────────────────────────────────────
            ;; File paths are in unevaluated forms — career/file is called
            ;; lazily at capture time, not at registration time.
            (add-to-list 'org-capture-templates '("c" "Career") t)

            (add-to-list 'org-capture-templates
                         '("cr" "Quick Result Log" entry
                           (file (career/file "projects.org"))
                           "* TODO Log result: %?\n  :PROPERTIES:\n  :DATE: %T\n  :END:\n  Result: \n  Project: \n  %a"
                           :prepend t :empty-lines 1)
                         t)

            (add-to-list 'org-capture-templates
                         '("cq" "Interview Question Gap" entry
                           (file+headline (career/file "interviews.org") "Gaps to Fill")
                           "* %?\n  :PROPERTIES:\n  :DATE: %T\n  :END:\n  Question: \n  How I answered: \n  Better answer: "
                           :prepend t :empty-lines 1)
                         t)

            (add-to-list 'org-capture-templates
                         '("cs" "New Skill / Tech Used" entry
                           (file+headline (career/file "skills.org") "Inbox")
                           "* %?\n  :PROPERTIES:\n  :DATE: %T\n  :PROFICIENCY: beginner\n  :LAST_USED: %<%Y-%m-%d>\n  :END:\n  What I did with it: \n  Resources: "
                           :prepend t :empty-lines 1)
                         t)

            ;; ── PRIMED capture templates ────────────────────────────────────
            ;; "P" group — PRIMED project framework.
            ;; :immediate-finish t skips the capture buffer entirely,
            ;; so the whole flow is minibuffer-only.
            (add-to-list 'org-capture-templates '("P" "PRIMED") t)

            (add-to-list 'org-capture-templates
                         '("Pm" "Quick Measurement" plain
                           (file+function (career/file "primed.org")
                                          primed--capture-goto-measure)
                           "   [%<%Y-%m-%d>] %^{Metric}: %^{Value} vs %^{Expected} — %^{Note}\n"
                           :immediate-finish t)
                         t)

            (add-to-list 'org-capture-templates
                         '("Pi" "New Increment" plain
                           (file+function (career/file "primed.org")
                                          primed--capture-goto-iterate)
                           "   - Increment: %^{Goal} | Expected: %^{Observable output} | Status: TODO\n"
                           :immediate-finish t)
                         t)

            (add-to-list 'org-capture-templates
                         '("Pb" "Blocked Note" plain
                           (file+function (career/file "primed.org")
                                          primed--capture-goto-iterate)
                           "   BLOCKED [%<%Y-%m-%d>]: %^{What is blocking you?}\n"
                           :immediate-finish t)
                         t)

            ;; ── Keybindings ─────────────────────────────────────────────────
            ;; SPC C prefix (capital C = Career).
            ;; SPC P prefix (capital P = PRIMED).
            ;; SPC c is taken by Code bindings in keybindings.el.
            (my/leader
              "C"   '(:ignore t                  :which-key "career")
              "C i" '(career/initialize          :which-key "initialize files")
              "C R" '(career/rewrite-readme      :which-key "rewrite README")
              "C p" '(career/new-project         :which-key "new project")
              "C s" '(career/new-star-story      :which-key "new STAR story")
              "C I" '(career/prep-for-interview  :which-key "interview prep")
              "C e" '(career/skill-evidence      :which-key "skill evidence")
              "C r" '(career/update-result       :which-key "log result")
              "C b" '(career/new-bom            :which-key "new BOM table")
              "C c" '(org-capture                :which-key "capture")

              "P"   '(:ignore t                  :which-key "PRIMED")
              "P n" '(primed/new-project         :which-key "new project")
              "P m" '(primed/log-measurement     :which-key "log measurement")
              "P s" '(primed/session-start       :which-key "session start")
              "P e" '(primed/session-end         :which-key "session end")
              "P c" '(primed/close-project       :which-key "close project")
              "P d" '(primed/dashboard           :which-key "dashboard"))))

;;; ── Health registration ──────────────────────────────────────────────────────

(with-eval-after-load 'mo-health
  (add-to-list 'my/health-check-features 'career t))

(provide 'career)
;;; career.el ends here
