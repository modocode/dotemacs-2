;;; modules/time-config.el --- Time tracking with org-clock + org-pomodoro -*- lexical-binding: t; -*-
;;
;; Built around org-clock (built-in).  org-pomodoro adds timed work sessions.
;; A hydra exposes the full menu under SPC l l; quick bindings live under SPC l.
;;
;; Clock data is persisted across restarts in var/org-clock-save.el (no-littering).

;;; ── org-clock ───────────────────────────────────────────────────────────────

(use-package org-clock
  :ensure nil          ; built into org, no elpaca install needed
  :after org
  :demand t
  :config
  ;; Persist the clock history across Emacs restarts.
  (setq org-clock-persist 'history)
  (org-clock-persistence-insinuate)

  ;; If you re-clock a task that is already running, resume it from where it left off.
  (setq org-clock-in-resume t)

  ;; Store CLOCK entries in the LOGBOOK drawer, not loose in the heading body.
  (setq org-clock-into-drawer t)

  ;; Discard clock entries that lasted 0 minutes (accidental clocks).
  (setq org-clock-out-remove-zero-time-clocks t)

  ;; Include the currently-clocking task in reports even while running.
  (setq org-clock-report-include-clocking-task t)

  ;; Show durations as h:mm (e.g. 1:30) rather than "1d 2h 3min".
  (setq org-duration-format 'h:mm))

;;; ── org-pomodoro ─────────────────────────────────────────────────────────────

(use-package org-pomodoro
  :ensure t
  :after org-clock
  :config
  (setq org-pomodoro-length              25   ; focused work block (minutes)
        org-pomodoro-short-break-length   5   ; break between pomodoros
        org-pomodoro-long-break-length   20   ; break after 4 pomodoros
        org-pomodoro-long-break-frequency 4))

;;; ── Clock hydra ──────────────────────────────────────────────────────────────
;; Stays resident until you press q, so you can chain clock actions without
;; re-pressing the prefix.

(with-eval-after-load 'hydra
  (defhydra hydra-clock (:hint nil)
    "
  ⏱  Time Tracking
  ─────────────── Clock ────────────────────   ──── Reports ────────────────
  _i_ clock in          _o_ clock out          _r_ report (buffer)
  _l_ last task         _g_ goto active        _d_ display totals
  _e_ set effort        _c_ cancel clock       _R_ report (subtree)
  ─────────────── Pomodoro ─────────────────
  _p_ start pomodoro    _q_ quit
"
    ("i" org-clock-in)
    ("o" org-clock-out)
    ("l" org-clock-in-last)
    ("g" org-clock-goto)
    ("e" org-set-effort)
    ("c" org-clock-cancel)
    ("p" org-pomodoro)
    ("r" org-clock-report)
    ("d" org-clock-display)
    ("R" (org-clock-report '(4)))  ; prefix arg → report on current subtree
    ("q" nil :exit t)))

(provide 'time-config)
;;; time-config.el ends here
