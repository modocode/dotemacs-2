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
  ;(tab-bar-mode 1)
  )

;;; Centaur-Tabs

(use-package centaur-tabs
  :ensure t
  :demand
  :init
  (setq centaur-tabs-enable-key-bindings t)
  :config
  (setq centaur-tabs-set-icons t
        centaur-tabs-icon-type 'all-the-icons
	centaur-tabs-close-button "X"
	)
  
  (centaur-tabs-mode t)
  :bind
  ("C-<prior>" . centaur-tabs-backward)
  ("C-<next>" . centaur-tabs-forward)
  ("C-S-<prior>" . centaur-tabs-move-current-tab-to-left)
  ("C-S-<next>" . centaur-tabs-move-current-tab-to-right)
  )

(provide 'tabs-config)
;;; tabs-config.el ends here
