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

(package-initialize)

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
          (load-theme 'doom-molokai t)))

(use-package doom-modeline
      :ensure t
      :hook (after-init . doom-modeline-mode)
      :config (progn
                (setq doom-modeline-icon nil
                      doom-modeline-bar-width 1)))

;; programming specific

(require 'prettier-js)

(use-package company
  :defer t
  :commands global-company-mode
  :diminish company-mode
  :init (progn
          (add-hook 'after-init-hook 'global-company-mode)
          (global-set-key (kbd "C-.") #'company-complete))
  :config (progn
            (add-to-list 'company-backends 'company-lsp)
            (setq company-minimum-prefix-length 2
                  company-idle-delay 0
                  company-tooltip-idle-delay 0))
  :pin gnu)

(with-eval-after-load 'company
    (add-hook 'emacs-lisp-mode-hook
        '(lambda ()
         (require 'company-elisp)
         (push 'company-elisp company-backends))))

(use-package web-mode
  :ensure t
  :commands web-mode
  :mode (("\\.html$" . web-mode)
         ("\\.ts$" . web-mode)
         ("\\.tsx$" . web-mode)
	 ("\\.js$" . web-mode))
  :config (progn
            (setq web-mode-markup-indent-offset 2)
            (setq web-mode-css-indent-offset 2)
            (setq web-mode-code-indent-offset 2)

            (add-hook 'web-mode-hook 'electric-pair-mode)
            (add-hook 'web-mode-hook 'electric-indent-mode))
  :pin melpa-stable)

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

(use-package exec-path-from-shell
  :ensure t
  :pin melpa-stable
  :init (progn
          (when (memq window-system '(mac ns x))
            (exec-path-from-shell-initialize))))

(use-package flycheck
  :after git-gutter-fringe
  :commands flycheck-mode
  :diminish flycheck-mode
  :init (progn
          (add-hook 'flycheck-mode-hook 'flycheck-rust-setup))
  :config (setq flycheck-indication-mode 'left-fringe)
  :pin melpa-stable)

;; cloudformation-mode
(define-derived-mode cfn-mode yaml-mode
  "Cloudformation"
  "Cloudformation template mode.")

(add-to-list 'auto-mode-alist '(".template\\'" . cfn-mode))

(with-eval-after-load 'flycheck
  (flycheck-define-checker cfn-lint
    "A Cloudformation linter using cfn-python-lint.

See URL 'https://github.com/awslabs/cfn-python-lint'."
    :command ("cfn-lint" "-f" "parseable" source)
    :error-patterns (
                     (warning line-start (file-name) ":" line ":" column
                              ":" (one-or-more digit) ":" (one-or-more digit) ":"
                              (id "W" (one-or-more digit)) ":" (message) line-end)
                     (error line-start (file-name) ":" line ":" column
                            ":" (one-or-more digit) ":" (one-or-more digit) ":"
                            (id "E" (one-or-more digit)) ":" (message) line-end)
                     )
    :modes (cfn-mode)
    )
  (add-to-list 'flycheck-checkers 'cfn-lint))

;; typescript and javascript
(use-package tide
  :after web-mode
  :ensure t
  :commands tide-mode
  :init (progn
          (add-hook 'web-mode-hook 'tide-mode)
          (flycheck-add-mode 'javascript-eslint 'web-mode))
  :config (progn
            (defun tide-flycheck-setup ()
              (flycheck-mode 1)
              (flycheck-select-checker 'javascript-eslint))
            (defun tide-flycheck-set-default-dir ()
              (setq default-directory
                    (locate-dominating-file default-directory "tsconfig.json")))

            (add-hook 'tide-mode-hook 'tide-flycheck-set-default-dir)
            (add-hook 'tide-mode-hook 'tide-flycheck-setup)
            (add-hook 'tide-mode-hook 'prettier-js-mode)
            (add-hook 'tide-mode-hook 'tide-hl-identifier-mode)
            
            (setq web-mode-code-indent-offset 2
                  web-mode-markup-indent-offset 2

                  tide-always-show-documentation t
                  tide-completion-detailed t)))

;; python config
(use-package python
  :ensure t
  :mode ("\\.py\\'" . python-mode)
  :interpreter ("python" . python-mode))

(use-package elpy
  :ensure t
  :defer t
  :init
  (elpy-enable))

(use-package company-jedi
  :ensure t
  :disabled t
  :hook (python-mode . (lambda ()
                         (push 'company-jedi company-backends)
                         (add-hook 'python-mode-hook 'jedi:setup)))
  :config
  (setq jedi:complete-on-dot t))

;; haskell config
(use-package haskell-mode
  :ensure t
  :mode (("\\.hs\\'"    . haskell-mode)
         ("\\.cabal\\'" . haskell-cabal-mode)
         ("\\.hcr\\'"   . haskell-core-mode))
  :interpreter ("haskell" . haskell-mode)

  :init
  (add-hook 'haskell-mode-hook 'structured-haskell-mode)
  (add-hook 'haskell-mode-hook 'interactive-haskell-mode)
  (add-hook 'haskell-mode-hook (lambda () (yas-minor-mode)))

  :config
  (require 'haskell)
  (require 'haskell-mode)
  (require 'haskell-interactive-mode)
  (require 'autoinsert))

;; c/cpp config
(use-package irony
  :ensure t
  :config
  (progn
    (use-package company-irony
      :ensure t
      :config
      (add-to-list 'company-backends 'company-irony))
    (add-hook 'irony-mode-hook 'electric-pair-mode)
    (add-hook 'c++-mode-hook 'irony-mode)
    (add-hook 'c-mode-hook 'irony-mode)
    (add-hook 'irony-mode-hook 'my-irony-mode-hook)
    (add-hook 'irony-mode-hook 'company-irony-setup-begin-commands)
    (add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)))
