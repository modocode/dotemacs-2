;;; modules/tabs-config.el --- Tab bar configuration -*- lexical-binding: t; -*-
;;
;; Two tab layers:
;;   tab-bar-mode  — built-in workspace tabs (Emacs 27+). Each tab is an
;;                   independent window layout. Think of them like tmux windows.
;;   awesome-tab   — buffer tabs within the current workspace, grouped by
;;                   project root or major mode.
;;

;;; ── Built-in workspace tabs ──────────────────────────────────────────────────

;; (use-package tab-bar
;;   :ensure nil                           ; built-in
;;   :demand t
;;   :config
;;   (setq tab-bar-show                    t    ; hide bar when only one tab
;;         tab-bar-close-button-show       nil
;;         tab-bar-new-button-show         t
;;         tab-bar-format                  '(tab-bar-format-tabs-groups ; grouped view
;;                                           tab-bar-separator))
;;   (global-tab-bar-mode 1)
;;   )

(use-package tab-line
  :ensure nil ; Built-in since Emacs 27
  :demand t
  :bind (("C-<tab>" . tab-line-switch-to-next-tab)
         ("C-<iso-lefttab>" . tab-line-switch-to-prev-tab)
         ("C-S-<tab>" . tab-line-switch-to-prev-tab))
  :config
  (global-tab-line-mode 1)
  ;; Hide the "+ " and "x" buttons for a cleaner look
  (setq tab-line-new-button-show nil
        tab-line-close-button-show
        tab-line-separator ""))


(provide 'tabs-config)
;;; tabs-config.el ends here
