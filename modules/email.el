;;; email.el --- Notmuch frontend for Fastmail -*- lexical-binding: t; -*-

(autoload 'notmuch "notmuch" nil t)

(with-eval-after-load 'notmuch
  (setenv "NOTMUCH_CONFIG"
          (expand-file-name "notmuch/default/config"
                            (or (getenv "XDG_CONFIG_HOME") "~/.config")))
  (setq mail-user-agent 'notmuch-user-agent
        sendmail-program "msmtp"
        message-send-mail-function #'message-send-mail-with-sendmail
        message-sendmail-envelope-from 'header
        notmuch-fcc-dirs nil
        notmuch-show-empty-saved-searches t
        notmuch-saved-searches
        '((:name "Inbox" :query "folder:fastmail/Inbox and tag:inbox" :key "i")
          (:name "Unread" :query "folder:fastmail/Inbox and tag:unread" :key "u")
          (:name "Action" :query "tag:action" :key "t")
          (:name "Waiting" :query "tag:waiting" :key "w")
          (:name "Sent" :query "folder:fastmail/Sent" :key "s")
          (:name "All mail" :query "*" :key "a")))
  (setf (alist-get (kbd "t") notmuch-tagging-keys nil nil #'equal)
        '(("+action" "-waiting" "-inbox") "Action")
        (alist-get (kbd "w") notmuch-tagging-keys nil nil #'equal)
        '(("+waiting" "-action" "-inbox") "Waiting")
        (alist-get (kbd "c") notmuch-tagging-keys nil nil #'equal)
        '(("-action" "-waiting" "-inbox") "Done")))

(provide 'email)
;;; email.el ends here
