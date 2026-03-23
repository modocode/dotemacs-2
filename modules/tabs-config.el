;;; modules/tabs-config.el --- Tab bar configuration -*- lexical-binding: t; -*-
;;
;; Two tab layers:
;;   tab-bar-mode  — built-in workspace tabs (Emacs 27+). Each tab is an
;;                   independent window layout. Think of them like tmux windows.
;;   awesome-tab   — buffer tabs within the current workspace, grouped by
;;                   project root or major mode.
;;
;; Navigate both with SPC T (hydra-tabs defined in keybindings.el).

;;; ── Built-in workspace tabs ──────────────────────────────────────────────────

(use-package tab-bar
  :ensure nil                           ; built-in
  :demand t
  :config
  (setq tab-bar-show                    1    ; hide bar when only one tab
        tab-bar-close-button-show       nil
        tab-bar-new-button-show         nil
        tab-bar-tab-name-function       #'tab-bar-tab-name-current-with-count
        tab-bar-tab-group-function      #'tab-bar-tab-group-default ; show group name in bar
        tab-bar-format                  '(tab-bar-format-tabs-groups ; grouped view
                                          tab-bar-separator))
  (tab-bar-mode 1))

;;; ── awesome-tab buffer tabs ──────────────────────────────────────────────────
;; Not on MELPA — must supply an explicit elpaca recipe pointing to GitHub.

(use-package awesome-tab
  :ensure (:host github :repo "manateelazycat/awesome-tab")
  :demand t
  :config
  (setq awesome-tab-style                 'wave
        awesome-tab-height                 22
        awesome-tab-show-tab-index         t
        awesome-tab-buffer-groups-function #'awesome-tab-buffer-groups)
  (awesome-tab-mode 1))

(provide 'tabs-config)
;;; tabs-config.el ends here
