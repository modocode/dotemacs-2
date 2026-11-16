;;; modules/time-config.el --- Time tracking with org-clock + org-pomodoro -*- lexical-binding: t; -*-
;;


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


(use-package org-pomodoro
  :ensure t
  :after org-clock
  :config
  (setq org-pomodoro-length              25   ; focused work block (minutes)
        org-pomodoro-short-break-length   5   ; break between pomodoros
        org-pomodoro-long-break-length   20   ; break after 4 pomodoros
        org-pomodoro-long-break-frequency 4))


(provide 'time-config)
;;; time-config.el ends here
