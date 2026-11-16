;;; modules/elfeed-config.el --- RSS/Atom feed reader -*- lexical-binding: t; -*-
;;
;; Add feeds below, or use add-to-list in os/*.el:
;;   (add-to-list 'my/elfeed-feeds '("https://example.com/feed.xml" blog tech))
;; Entries are URL strings or (URL TAG TAG …).  Filter with +tech -blog.
;; After editing this file, run M-x eval-buffer, then M-x elfeed-update.
;; M-x elfeed opens the feed reader.

(require 'cl-lib)

(defvar my/elfeed-feeds nil
  "Master feed list consumed by Elfeed.
Extend from os/*.el with add-to-list.  Entries are URLs or (URL TAG …).")

(defvar my/elfeed--defaults nil
  "Previous configured defaults, used to preserve OS additions on reload.")

(defvar my/elfeed--synced-feeds nil
  "Previous registry snapshot, used to preserve interactive additions.")

(defun my/elfeed--feed-url (feed)
  "Return the URL from FEED, a string or tagged list."
  (if (stringp feed) feed (car feed)))

(defun my/elfeed--merge-feeds (configured current previous)
  "Combine CONFIGURED with independent entries from CURRENT.
Replace entries owned by CONFIGURED or PREVIOUS by URL, so config
edits and removals apply without discarding independent additions."
  (let ((owned-urls (mapcar #'my/elfeed--feed-url
                            (append configured previous))))
    (append (copy-tree configured)
            (cl-remove-if
             (lambda (feed)
               (member (my/elfeed--feed-url feed) owned-urls))
             current))))

;; Apply edits on reload while retaining additions from os/*.el.
(let ((defaults '(("https://hnrss.org/frontpage" hackernews tech)
                  ("https://joshblais.com/index.xml" emacs)
                  ("https://www.currentaffairs.org/news/rss.xml" politics news)
		  ("https://blog.rootsofprogress.org/feed.xml" acceleration future)
		  ("https://www.worksinprogress.news/feed" culture)
		  ("https://www.alignmentforum.org/feed.xml" ai allignment safety)
		  ("https://www.lesswrong.com/feed.xml?view=curated-rss" ai safety)
		  ("https://metr.org/blog/rss.xml" ai models safety)
		  ("https://www.rtl-sdr.com/?utm_source=chatgpt.com" rf engr )
		  ("https://www.microwavejournal.com/?utm_source=chatgpt.com" rf engr)
		  ("https://www.twz.com/feed" warfare defense)
		  ("https://singularityhub.com/feed" singularity)
		  ("https://thezvi.substack.com/feed" singularity culture)
		  ;; General cryptocurrency news
		  ("https://www.coindesk.com/arc/outboundfeeds/rss/"
		   crypto news)
		  ("https://www.theblock.co/rss.xml"
		   crypto news)
		  ("https://decrypt.co/feed"
		   crypto news)
		  ("https://protos.com/feed"
		   crypto investigations)

		  ;; Bitcoin
		  ("https://bitcoinops.org/feed.xml"
		   bitcoin technical)
		  ("https://bitcoinmagazine.com/feed"
		   bitcoin news)

		  ;; Monero
		  ("https://monero.observer/feed-stories.xml"
		   monero privacy)
		  ("https://www.getmonero.org/feed.xml"
		   monero development)

		  ;; Cryptography and blockchain security
		  ("https://blog.trailofbits.com/feed/"
		   cryptography security)
		  ("https://blog.ethereum.org/feed.xml"
		   ethereum development)
		  ("https://rekt.news/rss.xml"
		   crypto security)

		  ;; nixos 
		  ("https://nixos.org/blog/feed.xml" nix official)
		  ("https://determinate.systems/rss.xml" nix technical)
		  ("https://nixcademy.com/feed.xml" nix tutorial)
		  ("https://planet.nixos.org/atom.xml" nix community)
		  ("https://discourse.nixos.org/c/announcements/8.rss" nix announcements)

		  ;; Linux internals and hardware
		  ("https://lwn.net/headlines/rss" linux kernel)
		  ("https://www.phoronix.com/rss.php" linux hardware)

		  ;; Open source and engineering
		  ("https://drewdevault.com/blog/index.xml" opensource)
		  ("https://jvns.ca/atom.xml" linux systems)
		  ("https://www.brendangregg.com/blog/rss.xml" linux performance)
		  ("https://xeiaso.net/blog.rss" nix opensource)

		  ;; General open-source news
		  ("https://news.itsfoss.com/feed/" linux news)
		  )))
  (setq my/elfeed-feeds
        (my/elfeed--merge-feeds defaults my/elfeed-feeds my/elfeed--defaults)
        my/elfeed--defaults (copy-tree defaults)))

(defun my/elfeed-sync-feeds (&rest _)
  "Apply the registry to Elfeed while preserving interactive additions."
  (setq elfeed-feeds
        (my/elfeed--merge-feeds my/elfeed-feeds elfeed-feeds
                                my/elfeed--synced-feeds)
        my/elfeed--synced-feeds (copy-tree my/elfeed-feeds)))

(defun my/elfeed-mark-all-read ()
  "Mark every entry currently visible in the elfeed search buffer as read."
  (interactive)
  (mark-whole-buffer)
  (elfeed-search-untag-all-unread))

(use-package elfeed
  :ensure t
  :defer t
  :custom
  (elfeed-search-filter "@6-months-ago +unread")
  (elfeed-db-directory (my/var-dir "elfeed/db/")))

;; Run immediately on reload even when Elpaca queues use-package forms.
(with-eval-after-load 'elfeed
  ;; Remove the old hook when upgrading an already running Emacs.
  (remove-hook 'elfeed-search-mode-hook
               #'(lambda () (setq elfeed-feeds my/elfeed-feeds)))
  (my/elfeed-sync-feeds)
  ;; Elfeed's update-init hooks run AFTER it gathers the feed URLs.
  (advice-add 'elfeed-update :before #'my/elfeed-sync-feeds))


;;; Tag completion and full-article reading

(require 'crm)
(defvar eww-mode-hook)

(defun my/elfeed-filter-tag-candidates ()
  "Return include/exclude candidates for database and configured tags."
  (let ((tags (delete-dups
               (append '(unread)
                       (elfeed-db-get-all-tags)
                       (cl-loop for feed in my/elfeed-feeds
                                when (consp feed) append (cdr feed))))))
    (sort (cl-loop for tag in tags
                   append (list (concat "+" (symbol-name tag))
                                (concat "-" (symbol-name tag))))
          #'string<)))

(defun my/elfeed-filter-tags ()
  "Choose filter tags with completion, preserving date and text filters.
Select +TAG to include a tag or -TAG to exclude it.  Separate multiple
selections with commas.  An empty selection removes tag constraints."
  (interactive)
  (unless (derived-mode-p 'elfeed-search-mode)
    (user-error "Choose tags from the Elfeed search buffer"))
  (let* ((terms (split-string elfeed-search-filter))
         (tag-p (lambda (term) (string-match-p "\\`[+-]" term)))
         (current-tags (cl-remove-if-not tag-p terms))
         (other-terms (cl-remove-if tag-p terms))
         (crm-separator "[ \t]*,[ \t]*")
         (tags (completing-read-multiple
                "Filter tags (+include, -exclude; comma separated): "
                (my/elfeed-filter-tag-candidates) nil t
                (mapconcat #'identity current-tags ","))))
    (elfeed-search-set-filter
     (mapconcat #'identity (append other-terms (delete-dups tags)) " "))))

(defun my/elfeed-filter-tag-completion ()
  "Complete the signed tag token at point in an Elfeed filter prompt."
  (let ((end (point))
        (start (save-excursion
                 (skip-chars-backward "^ \t\n")
                 (point))))
    (when (and (< start end) (memq (char-after start) '(?+ ?-)))
      (list start end (my/elfeed-filter-tag-candidates) :exclusive 'no))))

(defun my/elfeed-filter-minibuffer-setup ()
  "Enable TAB completion only in Elfeed's filter minibuffers."
  (when (bound-and-true-p elfeed-search-filter-active)
    (add-hook 'completion-at-point-functions
              #'my/elfeed-filter-tag-completion nil t)
    (use-local-map (copy-keymap (current-local-map)))
    (local-set-key (kbd "TAB") #'completion-at-point)))

(add-hook 'minibuffer-setup-hook #'my/elfeed-filter-minibuffer-setup)

(defun my/elfeed--readable-once ()
  "Extract the article after its first EWW render."
  (remove-hook 'eww-after-render-hook #'my/elfeed--readable-once t)
  (condition-case err
      (eww-readable)
    (error (message "Showing the page without extraction: %s"
                    (error-message-string err)))))

(defun my/elfeed--setup-article-reader ()
  "Arrange article extraction in this new EWW buffer."
  (add-hook 'eww-after-render-hook #'my/elfeed--readable-once nil t))

(defun my/elfeed-read-full-article ()
  "Fetch the current entry's linked page in a new EWW reading buffer.
Leave the feed's original content intact.  Use Zen for pages that need
JavaScript or a login."
  (interactive)
  (let* ((entry (cond
                 ((derived-mode-p 'elfeed-show-mode) elfeed-show-entry)
                 ((derived-mode-p 'elfeed-search-mode)
                  (car (elfeed-search-selected t)))))
         (url (and entry (elfeed-entry-link entry))))
    (unless (and (stringp url) (string-match-p "\\`https?://" url))
      (user-error "No article web link at point"))
    (require 'eww)
    (let ((eww-mode-hook (cons #'my/elfeed--setup-article-reader eww-mode-hook)))
      (eww url t))))

(with-eval-after-load 'elfeed-search
  (define-key elfeed-search-mode-map (kbd "t") #'my/elfeed-filter-tags)
  (define-key elfeed-search-mode-map (kbd "F") #'my/elfeed-read-full-article))

(with-eval-after-load 'elfeed-show
  (define-key elfeed-show-mode-map (kbd "F") #'my/elfeed-read-full-article))

;; In Elfeed: t picks tags; s then TAB completes +tags/-tags; F reads the page.

(provide 'elfeed-config)
;;; elfeed-config.el ends here
