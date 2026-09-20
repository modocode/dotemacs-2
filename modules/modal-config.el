;;; modal-config.el --- Activate the personal modal editor -*- lexical-binding: t; -*-

(require 'mo-modal)

(when (eq my/modal-backend 'mo-modal)
  (use-package god-mode
    :ensure (:wait t)
    :demand t
    :init
    (setq god-mode-enable-function-key-translation nil)
    :config
    ;; Reloading init after a backend change must not leave competing maps.
    (when (bound-and-true-p meow-global-mode) (meow-global-mode -1))
    (when (bound-and-true-p evil-mode) (evil-mode -1))
    (when (bound-and-true-p selected-global-mode) (selected-global-mode -1))
    (mo-modal-global-mode 1)))

(defun my/modal-writing-buffer ()
  "Start capture and commit input in Write even in an existing modal buffer."
  (when (bound-and-true-p mo-modal-mode) (mo-modal-enter-write)))

(add-hook 'org-capture-mode-hook #'my/modal-writing-buffer)
(add-hook 'with-editor-mode-hook #'my/modal-writing-buffer)

(provide 'modal-config)
;;; modal-config.el ends here
