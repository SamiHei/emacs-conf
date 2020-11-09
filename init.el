;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; startup settings

;; no startup screen
(setq inhibit-startup-message t)

(defconst user-site-lisp-directory
  (expand-file-name "site-lisp/" user-emacs-directory))

;; save custom variables to their own file
(setq custom-file (concat (file-name-as-directory user-emacs-directory) "custom.el"))
(unless (file-exists-p custom-file)
  (with-temp-buffer (write-file custom-file)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; global settings
(global-visual-line-mode t)
(global-linum-mode t)

(setq-default indent-tabs-mode nil)

;; make sure all backup files only live in one place
(setq backup-directory-alist '(("." . "~/.emacs-backups")))
(setq backup-inhibited t)

;; y/n instead of yes/no
(defalias 'yes-or-no-p 'y-or-n-p)

;; show mark and region
(setq transient-mark-mode t)

;; show line and column numbers on the modeline
(setq line-number-mode t)
(setq column-number-mode t)

;; no autosave
(setq auto-save-default nil)

;; delete region by writing or by backspace
(delete-selection-mode 1)

;; explicitly show the end of a buffer
(set-default 'indicate-empty-lines t)

;; faster buffer killing
(global-set-key (kbd "M-k") #'kill-this-buffer)

(global-set-key (kbd "C-;") 'comment-or-uncomment-region-or-line)

;; org mode binding
(define-key global-map "\C-cl" 'org-store-link)
(define-key global-map "\C-ca" 'org-agenda)

;; show matching parens
(show-paren-mode t)

;; use python3
(setq py-python-command "python3")
(setq elpy-rpc-python-command "python3")

;; faster switching between frames
(global-set-key [M-left] 'windmove-left)
(global-set-key [M-right] 'windmove-right)
(global-set-key [M-up] 'windmove-up)
(global-set-key [M-down] 'windmove-down)

;; package archives
(require 'package)
(setq package-enable-at-startup nil)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(add-to-list 'package-archives '("melpa-stable" . "https://stable.melpa.org/packages/"))
(add-to-list 'package-archives                                                                                                        
             '("elpy" . "http://jorgenschaefer.github.io/packages/")) 

(package-initialize)

(unless package-archive-contents
  (package-refresh-contents))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; package settings
(use-package swiper
  :ensure t
  :pin melpa-stable)

(use-package counsel
  :ensure t
  :pin melpa-stable)

(use-package ivy
  :ensure t
  :pin melpa-stable
  :init (ivy-mode 1)
  :config (progn
            (setq enable-recursive-minibuffers t
                  ivy-height 16)
            (global-set-key (kbd "C-s") 'swiper)
            (global-set-key (kbd "C-r") 'swiper-backward)
            (global-set-key (kbd "M-x") 'counsel-M-x)
            (global-set-key (kbd "C-x b") 'counsel-switch-buffer)
            (define-key minibuffer-local-map (kbd "C-r") 'counsel-minibuffer-history)))

;; org mode
(use-package org
  :ensure t
  :mode ("\\.org$" . org.mode))

;; Load color theme
(use-package doom-themes
  :ensure t
  :init (progn
          (load-theme 'doom-Iosvkem t)))

(use-package doom-modeline
      :ensure t
      :hook (after-init . doom-modeline-mode)
      :config (progn
                (setq doom-modeline-icon nil
                      doom-modeline-bar-width 1)))

;; Documentation and data formats
(use-package json-mode
  :ensure t
  :mode ("\\.json$" . json-mode)
  :hook ((json-mode-hook . prettier-js-mode))
  :pin melpa-stable)

(use-package yaml-mode
  :ensure t
  :commands yaml-mode
  :mode ("\\.yaml$" . yaml-mode)
  :config (progn
            (add-hook 'yaml-mode-hook 'display-line-numbers-mode))
  :pin melpa-stable)

(use-package markdown-mode
  :ensure t
  :defer t
  :init (progn
          (add-hook 'markdown-mode-hook #'outline-minor-mode))
  :pin melpa-stable)

;;;;;;;;;;;;;;;;;;;;;;;
;; Programming specific

;; Auto-completion
(use-package company
  :ensure t
  :config
  (progn
    ;; Enable company mode in every programming mode
    (add-hook 'prog-mode-hook 'company-mode)
    ;; Set my own default company backends
    (setq-default
     company-backends
     '(
       company-nxml
       company-css
       company-cmake
       company-files
       company-dabbrev-code
       company-keywords
       company-dabbrev
       company-elisp
       ))
    )
  )

;; Syntax and style
(use-package flycheck
  :ensure t
  :init
  (progn
    ;; Enable flycheck mode as long as we're not in TRAMP
    (add-hook
     'prog-mode-hook
     (lambda () (if (not (is-current-file-tramp)) (flycheck-mode 1))))
    )
  )

;; C/C++
(use-package rtags
  :ensure t
  :config
  (progn
    ;; Start rtags upon entering a C/C++ file
    (add-hook
     'c-mode-common-hook
     (lambda () (if (not (is-current-file-tramp))
                    (rtags-start-process-unless-running))))
    (add-hook
     'c++-mode-common-hook
     (lambda () (if (not (is-current-file-tramp))
                    (rtags-start-process-unless-running))))
    ;; Flycheck setup
    (require 'flycheck-rtags)
    (defun my-flycheck-rtags-setup ()
      (flycheck-select-checker 'rtags)
      ;; RTags creates more accurate overlays.
      (setq-local flycheck-highlighting-mode nil)
      (setq-local flycheck-check-syntax-automatically nil))
    ;; c-mode-common-hook is also called by c++-mode
    (add-hook 'c-mode-common-hook #'my-flycheck-rtags-setup)
    ;; Keybindings
    (rtags-enable-standard-keybindings c-mode-base-map "\C-cr")
    )
  )

;; Use irony for completion
(use-package irony
  :ensure t
  :config
  (progn
    (add-hook
     'c-mode-common-hook
     (lambda () (if (not (is-current-file-tramp)) (irony-mode))))
    (add-hook
     'c++-mode-common-hook
     (lambda () (if (not (is-current-file-tramp)) (irony-mode))))
    (add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)
    (use-package company-irony
      :ensure t
      :config
      (push 'company-irony company-backends)
      )
    )
  )

;; Python
(use-package elpy :ensure t
  :defer t
  :init
  (advice-add 'python-mode :before 'elpy-enable))

;; Robot Framework
(defgroup robot-mode nil
  "Robot Framework major mode"
  :link '(url-link "https://github.com/wingyplus/robot-mode")
  :group 'languages)

(defconst robot-mode--header-keywords-re
  (regexp-opt '("Settings" "Test Cases" "Keywords" "Variables"))
  "Header keywords regexp")

(defconst robot-mode-header-three-star-re "\\*\\{3\\}")

(defconst robot-mode-whitespace-re "[ \t]+")

(defconst robot-mode-header-re
  (concat
    "^"
    robot-mode-header-three-star-re robot-mode-whitespace-re
    robot-mode--header-keywords-re
    robot-mode-whitespace-re robot-mode-header-three-star-re))

(defvar robot-mode-header
  `(,robot-mode-header-re . font-lock-keyword-face)
  "Header keywords")

(defconst robot-mode-settings-keywords-re
  (concat
    "^"
    (regexp-opt '("Library" "Resource" "Variables"
                   "Documentation" "Metadata" "Suite Setup"
                   "Suite Teardown" "Force Tags" "Default Tags"
                   "Test Setup" "Test Teardown" "Test Template"
                   "Test Timeout"))))

(defvar robot-mode-settings-keywords
  `(,robot-mode-settings-keywords-re . font-lock-keyword-face))

(defconst robot-mode-test-case-settings-keywords-re
  (regexp-opt '("Arguments" "Documentation" "Tags" "Setup"
		"Teardown" "Template" "Timeout" "Return"))
  "Test case settings keywords regexp")

(defconst robot-mode-test-case-settings-re
  (concat "\\[" robot-mode-test-case-settings-keywords-re "\\]"))

(defvar robot-mode-test-case-settings
  `(,robot-mode-test-case-settings-re . font-lock-keyword-face)
  "Test case settings keyword")

(defvar robot-mode-comment
  '("^[\s\ta-zA-Z0-9]*\\(#.*\\)$" . (1 font-lock-comment-face))
  (concat
    "Comment"
    "FIXME: it does not tokenizes when Test Case have embeded variable"))

(defvar robot-mode-variable
  '("[\\$&@]{.*?}" . font-lock-variable-name-face))

(defvar robot-mode-font-lock-keywords
  (list
    robot-mode-header
    robot-mode-settings-keywords
    robot-mode-test-case-settings
    robot-mode-comment
    robot-mode-variable)
  "All available keywords")

(define-derived-mode robot-mode fundamental-mode "Robot Framework"
  "A major mode for Robot Framework."
  (setq-local comment-start "# ")
  (setq-local font-lock-defaults
    '(robot-mode-font-lock-keywords)))

(add-to-list 'auto-mode-alist '("\\.robot\\'" . robot-mode))

(provide 'robot-mode)

