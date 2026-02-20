(defvar sys/is-mac (eq system-type 'darwin))
(defvar sys/is-linux (eq system-type 'gnu/linux))
(defvar sys/is-windows (memq  system-type '(ms-dos windows-nt cygwin)))


(add-to-list 'load-path (expand-file-name "core" user-emacs-directory))
(add-to-list 'load-path (expand-file-name "modules" user-emacs-directory))
(add-to-list 'load-path (expand-file-name "os" user-emacs-directory))


;; Loading Core Configuration
(require 'core-packages.el)
(require 'core-ui.el)
(require 'core-lib.el)



;; Load OS-specfic configuration 

(cond
 (sys/is-mac     (require 'macos nil t))
 (sys/is-linux   (require 'linux nil t))
 (sys/is-windows (require 'windows nil t)))
