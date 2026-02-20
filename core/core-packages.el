;;; core-packages.el --- Package Managment Setup -*- lexical-binding: t; _*_

(defvar bootstrap-version)
(let ((bootstrap-file
	(expand-file-name
	"straight/repos/straight.el/bootstrap.el"
	(or (bound-and-true-p straight-base-dir)
		user-emacs-directory)))
(bootstrap-version 7))
(unless (file-exists-p bootstrap-file)
	(with-current-buffer
	(url-retrieve-synchronously
	"https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
	'silent 'inhibit-cookies)
(goto-char (point-max))
(eval-print-last-sexp)))
(load bootstrap-file nil 'nomessage))
;; Disable package.el in favor of straight.el
(setq package-enable-at-startup nil)



(use-package straight
	:custom
	(straight-use-package-by-default t))

(use-package gcmh
  :config
  (gcmh-mode 1))



(provide 'core-packages.el)
