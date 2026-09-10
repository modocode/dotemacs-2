;;; my-nutrition.el --- Org-mode nutrition tracker -*- lexical-binding: t; -*-

(require 'org)
(require 'org-table)
(require 'calendar)
(require 'subr-x)
(require 'cl-lib)

(defgroup my/nutrition nil
  "Nutrition tracking with Org."
  :group 'org)

(defcustom my/nutrition-file
  (expand-file-name "~/org/nutrition.org")
  "Org file used as the nutrition database."
  :type 'file)

(defconst my/nutrition-nutrients
  '(("CALORIES" . "Calories")
    ("PROTEIN"  . "Protein")
    ("CARBS"    . "Carbs")
    ("FAT"      . "Fat")
    ("FIBER"    . "Fiber")
    ("SUGAR"    . "Sugar")
    ("SODIUM"   . "Sodium"))
  "Nutrition properties and their display names.")

(defun my/nutrition--buffer ()
  "Return the nutrition database buffer, visiting `my/nutrition-file`."
  (unless (file-exists-p my/nutrition-file)
    (make-directory (file-name-directory my/nutrition-file) t)
    (with-temp-file my/nutrition-file
      (insert "#+title: Nutrition\n\n"
              "* Foods :database:\n\n"
              "* Recipes :database:\n\n"
              "* Meals :database:\n\n"
              "| Date | Time | Meal | Item | Quantity | Unit | Calories | Protein | Carbs | Fat | Fiber | Sugar | Sodium |\n"
              "|-\n")))
  (find-file-noselect my/nutrition-file))

(defun my/nutrition-open ()
  "Open the nutrition database."
  (interactive)
  (pop-to-buffer (my/nutrition--buffer)))

(defun my/nutrition--goto-section (section)
  "Go to top-level SECTION in the nutrition database."
  (goto-char (point-min))
  (unless (re-search-forward
           (format "^\\* %s\\(?:[ \t]+.*\\)?$" (regexp-quote section))
           nil t)
    (user-error "Could not find section * %s" section))
  (beginning-of-line))

(defun my/nutrition--entry-at (name tag)
  "Find entry NAME carrying TAG and return point, or nil."
  (goto-char (point-min))
  (let ((found nil))
    (org-map-entries
     (lambda ()
       (when (and (string= (org-get-heading t t t t) name)
                  (member tag (org-get-tags)))
         (setq found (point))))
     (format "+%s" tag)
     'file)
    found))

(defun my/nutrition--entry-names (tag)
  "Return names of all entries carrying TAG."
  (let (names)
    (goto-char (point-min))
    (org-map-entries
     (lambda ()
       (push (org-get-heading t t t t) names))
     (format "+%s" tag)
     'file)
    (delete-dups (nreverse names))))

(defun my/nutrition--select-entry (&optional prompt)
  "Select a food or recipe with completion."
  (let* ((buf (my/nutrition--buffer))
         (foods (with-current-buffer buf
                  (my/nutrition--entry-names "food")))
         (recipes (with-current-buffer buf
                    (my/nutrition--entry-names "recipe")))
         (choices (append
                   (mapcar (lambda (x) (concat "Food: " x)) foods)
                   (mapcar (lambda (x) (concat "Recipe: " x)) recipes)))
         (choice (completing-read (or prompt "Food or recipe: ")
                                  choices nil t)))
    (string-remove-prefix
     (if (string-prefix-p "Food: " choice) "Food: " "Recipe: ")
     choice)))

(defun my/nutrition--goto-entry (name)
  "Find NAME as either a food or recipe and move point there."
  (or (my/nutrition--entry-at name "food")
      (my/nutrition--entry-at name "recipe")
      (user-error "No food or recipe named %s" name)))

(defun my/nutrition--number (property &optional default)
  "Read numeric PROPERTY at point, returning DEFAULT if absent."
  (let ((value (org-entry-get nil property)))
    (if (and value (not (string-empty-p value)))
        (string-to-number value)
      (or default 0))))

(defun my/nutrition--food-p ()
  "Return non-nil if point is at a food."
  (member "food" (org-get-tags)))

(defun my/nutrition--recipe-p ()
  "Return non-nil if point is at a recipe."
  (member "recipe" (org-get-tags)))

(defun my/nutrition--first-table ()
  "Return point of the first table in the current subtree."
  (save-excursion
    (org-back-to-heading t)
    (let ((end (save-excursion (org-end-of-subtree t t)))
          found)
      (while (and (< (point) end) (not found))
        (when (org-at-table-p)
          (setq found (point)))
        (forward-line 1))
      found)))

(defun my/nutrition--recipe-rows ()
  "Return ingredient rows from the recipe at point.
Each row is a cons of ingredient name and quantity."
  (let ((table (my/nutrition--first-table)))
    (unless table
      (user-error "Recipe has no ingredient table"))
    (save-excursion
      (goto-char table)
      (let ((data (org-table-to-lisp))
            rows)
        (dolist (row data)
          (when (and (listp row)
                     (>= (length row) 2)
                     (not (string-equal (string-trim (car row))
                                        "Ingredient")))
            (let ((name (string-trim (nth 0 row)))
                  (quantity (string-to-number (string-trim (nth 1 row)))))
              (unless (string-empty-p name)
                (push (cons name quantity) rows)))))
        (nreverse rows)))))

(defun my/nutrition--calculate (name quantity &optional stack)
  "Calculate nutrients for NAME consumed in QUANTITY.

For foods, QUANTITY is expressed in the food's UNIT.
For recipes, QUANTITY is the number of recipe servings.
STACK prevents recursive recipe definitions."
  (let ((stack (or stack '())))
    (when (member name stack)
      (user-error "Circular recipe dependency involving %s" name))
    (with-current-buffer (my/nutrition--buffer)
      (my/nutrition--goto-entry name)
      (cond
       ((my/nutrition--food-p)
        (let* ((serving (my/nutrition--number "SERVING" 1))
               (factor (/ (float quantity) (max serving 0.000001)))
               result)
          (dolist (nutrient my/nutrition-nutrients)
            (push (cons (car nutrient)
                        (* factor
                           (my/nutrition--number (car nutrient))))
                  result))
          (push (cons "UNIT" (or (org-entry-get nil "UNIT") "unit"))
                result)
          (nreverse result)))

       ((my/nutrition--recipe-p)
        (let ((result
               (mapcar (lambda (x) (cons (car x) 0.0))
                       my/nutrition-nutrients)))
          (dolist (ingredient (my/nutrition--recipe-rows))
            (let* ((ingredient-name (car ingredient))
                   (ingredient-quantity (cdr ingredient))
                   (values
                    (my/nutrition--calculate
                     ingredient-name
                     ingredient-quantity
                     (cons name stack))))
              (dolist (nutrient my/nutrition-nutrients)
                (let ((cell (assq (car nutrient) result)))
                  (setcdr cell
                          (+ (cdr cell)
                             (cdr (assq (car nutrient) values))))))))
          ;; A recipe represents one serving when consumed.
          (let ((servings (max 1
                                (my/nutrition--number "SERVINGS" 1))))
            (dolist (pair result)
              (setcdr pair (/ (cdr pair) servings))))
          (push (cons "UNIT" "serving") result)
          result))

       (t
        (user-error "%s is neither a :food: nor :recipe:"
                    name))))))

(defun my/nutrition--value (values key)
  "Get KEY from calculated VALUES."
  (or (cdr (assq key values)) 0.0))

(defun my/nutrition--insert-properties (alist)
  "Insert property ALIST at the current Org heading."
  (dolist (pair alist)
    (org-set-property (car pair) (cdr pair))))

(defun my/nutrition-new-food ()
  "Create a new food entry."
  (interactive)
  (let* ((buf (my/nutrition--buffer))
         (name (read-string "Food name: "))
         (unit (read-string "Unit (g, ml, piece, etc.): " "g"))
         (serving (read-number "Serving size: " 100))
         (calories (read-number "Calories: " 0))
         (protein (read-number "Protein (g): " 0))
         (carbs (read-number "Carbs (g): " 0))
         (fat (read-number "Fat (g): " 0))
         (fiber (read-number "Fiber (g): " 0))
         (sugar (read-number "Sugar (g): " 0))
         (sodium (read-number "Sodium (mg): " 0)))
    (with-current-buffer buf
      (my/nutrition--goto-section "Foods")
      (goto-char (save-excursion (org-end-of-subtree t t)))
      (unless (bolp)
        (insert "\n"))
      (insert "\n** " name " :food:\n")
      (forward-line -1)
      (my/nutrition--insert-properties
       `(("UNIT" . ,unit)
         ("SERVING" . ,(number-to-string serving))
         ("CALORIES" . ,(number-to-string calories))
         ("PROTEIN" . ,(number-to-string protein))
         ("CARBS" . ,(number-to-string carbs))
         ("FAT" . ,(number-to-string fat))
         ("FIBER" . ,(number-to-string fiber))
         ("SUGAR" . ,(number-to-string sugar))
         ("SODIUM" . ,(number-to-string sodium))))
      (save-buffer)
      (org-back-to-heading t)
      (pop-to-buffer buf))))

(defun my/nutrition-new-recipe ()
  "Create a recipe and an empty ingredient table."
  (interactive)
  (let* ((buf (my/nutrition--buffer))
         (name (read-string "Recipe name: "))
         (servings (read-number "Number of servings: " 1)))
    (with-current-buffer buf
      (my/nutrition--goto-section "Recipes")
      (goto-char (save-excursion (org-end-of-subtree t t)))
      (unless (bolp)
        (insert "\n"))
      (insert "\n** " name " :recipe:\n")
      (forward-line -1)
      (org-set-property "SERVINGS" (number-to-string servings))
      (insert "\n| Ingredient | Quantity |\n|-\n")
      (org-table-align)
      (save-buffer)
      (org-back-to-heading t)
      (pop-to-buffer buf))))

(defun my/nutrition-add-ingredient ()
  "Append an ingredient to the recipe at point."
  (interactive)
  (unless (my/nutrition--recipe-p)
    (user-error "Not at a recipe"))
  (let* ((name (my/nutrition--select-entry "Ingredient: "))
         (unit (with-current-buffer (my/nutrition--buffer)
                 (my/nutrition--goto-entry name)
                 (or (org-entry-get nil "UNIT") "unit")))
         (quantity (read-number (format "Quantity (%s): " unit) 1))
         (table (my/nutrition--first-table)))
    (unless table
      (user-error "Recipe has no ingredient table"))
    (goto-char table)
    (org-table-end)
    (beginning-of-line)
    (insert (format "| %s | %s |\n"
                    name
                    (number-to-string quantity)))
    (org-table-align)
    (save-buffer)))

(defun my/nutrition--ensure-meal-table ()
  "Ensure the Meals section contains a meal log table.
Return the table's point."
  (my/nutrition--goto-section "Meals")
  (or (my/nutrition--first-table)
      (progn
        (goto-char (save-excursion (org-end-of-subtree t t)))
        (insert "\n| Date | Time | Meal | Item | Quantity | Unit | Calories | Protein | Carbs | Fat | Fiber | Sugar | Sodium |\n"
                "|-\n")
        (forward-line -2)
        (org-table-align)
        (point))))

(defun my/nutrition-log ()
  "Log a food or recipe in the Meals table."
  (interactive)
  (let* ((name (my/nutrition--select-entry "Log food/recipe: "))
         (recipe-p (with-current-buffer (my/nutrition--buffer)
                     (my/nutrition--goto-entry name)
                     (my/nutrition--recipe-p)))
         (unit (with-current-buffer (my/nutrition--buffer)
                 (my/nutrition--goto-entry name)
                 (if recipe-p
                     "serving"
                   (or (org-entry-get nil "UNIT") "unit"))))
         (quantity (read-number (format "Quantity (%s): " unit) 1))
         (meal (completing-read "Meal: "
                                '("Breakfast" "Lunch" "Dinner" "Snack")
                                nil t))
         (values (my/nutrition--calculate name quantity))
         (date (format-time-string "%Y-%m-%d"))
         (time (format-time-string "%H:%M"))
         (buf (my/nutrition--buffer)))
    (with-current-buffer buf
      (let ((table (my/nutrition--ensure-meal-table)))
        (goto-char table)
        (org-table-end)
        (beginning-of-line)
        (insert
         (format
          "| %s | %s | %s | %s | %s | %s | %.2f | %.2f | %.2f | %.2f | %.2f | %.2f | %.2f |\n"
          date time meal name quantity unit
          (my/nutrition--value values "CALORIES")
          (my/nutrition--value values "PROTEIN")
          (my/nutrition--value values "CARBS")
          (my/nutrition--value values "FAT")
          (my/nutrition--value values "FIBER")
          (my/nutrition--value values "SUGAR")
          (my/nutrition--value values "SODIUM")))
        (org-table-align)
        (save-buffer)
        (message "Logged %s (%s %s)" name quantity unit)))))

(defun my/nutrition--meal-table ()
  "Return point of the Meals table."
  (my/nutrition--goto-section "Meals")
  (my/nutrition--first-table))

(defun my/nutrition--meal-rows ()
  "Return parsed meal rows from the Meals table."
  (let ((buf (my/nutrition--buffer)))
    (with-current-buffer buf
      (let ((table (my/nutrition--meal-table)))
        (unless table
          (user-error "No Meals table"))
        (goto-char table)
        (cl-remove-if
         (lambda (row)
           (or (eq row 'hline)
               (not (listp row))
               (string= (or (nth 0 row) "") "Date")))
         (org-table-to-lisp))))))

(defun my/nutrition--date-row-p (row date)
  "Return non-nil if meal ROW has DATE."
  (and (listp row)
       (>= (length row) 13)
       (string= (nth 0 row) date)))

(defun my/nutrition--aggregate (rows)
  "Aggregate nutrition totals from meal ROWS."
  (let ((totals (mapcar (lambda (x) (cons (car x) 0.0))
                        my/nutrition-nutrients)))
    (dolist (row rows)
      (when (and (listp row)
                 (>= (length row) 13))
        (cl-loop for nutrient in my/nutrition-nutrients
                 for column from 6
                 do
                 (let ((cell (assq (car nutrient) totals)))
                   (setcdr cell
                           (+ (cdr cell)
                              (string-to-number
                               (or (nth column row) "0"))))))))
    totals))

(defun my/nutrition-today ()
  "Display today's nutrition totals."
  (interactive)
  (let* ((date (format-time-string "%Y-%m-%d"))
         (rows (my/nutrition--meal-rows))
         (today (cl-remove-if-not
                 (lambda (row)
                   (my/nutrition--date-row-p row date))
                 rows))
         (totals (my/nutrition--aggregate today)))
    (my/nutrition--display-summary
     (format "Nutrition — %s" date)
     today
     totals)))

(defun my/nutrition--iso-date (date)
  "Convert calendar DATE to YYYY-MM-DD."
  (format "%04d-%02d-%02d"
          (nth 2 date)
          (nth 0 date)
          (nth 1 date)))

(defun my/nutrition--week-dates ()
  "Return ISO dates for Monday through Sunday of this week."
  (let* ((today (calendar-current-date))
         (dow (calendar-day-of-week today))
         (monday
          (calendar-gregorian-from-absolute
           (- (calendar-absolute-from-gregorian today)
              (mod (1- dow) 7)))))
    (mapcar
     (lambda (offset)
       (my/nutrition--iso-date
        (calendar-gregorian-from-absolute
         (+ (calendar-absolute-from-gregorian monday)
            offset))))
     (number-sequence 0 6))))

(defun my/nutrition-week ()
  "Display nutrition totals for the current Monday-Sunday week."
  (interactive)
  (let* ((dates (my/nutrition--week-dates))
         (rows (my/nutrition--meal-rows))
         (buf (get-buffer-create "*Nutrition Week*")))
    (with-current-buffer buf
      (erase-buffer)
      (org-mode)
      (insert "#+title: Nutrition Week\n\n")
      (insert
       "| Date | Calories | Protein | Carbs | Fat | Fiber | Sugar | Sodium |\n"
       "|-\n")
      (dolist (date dates)
        (let* ((day (cl-remove-if-not
                     (lambda (row)
                       (my/nutrition--date-row-p row date))
                     rows))
               (totals (my/nutrition--aggregate day)))
          (insert
           (format
            "| %s | %.0f | %.1f | %.1f | %.1f | %.1f | %.1f | %.0f |\n"
            date
            (my/nutrition--value totals "CALORIES")
            (my/nutrition--value totals "PROTEIN")
            (my/nutrition--value totals "CARBS")
            (my/nutrition--value totals "FAT")
            (my/nutrition--value totals "FIBER")
            (my/nutrition--value totals "SUGAR")
            (my/nutrition--value totals "SODIUM")))))
      (org-table-align)
      (goto-char (point-min)))
    (pop-to-buffer buf)))

(defun my/nutrition--display-summary (title rows totals)
  "Display TITLE, ROWS and aggregate TOTALS."
  (let ((buf (get-buffer-create "*Nutrition Today*")))
    (with-current-buffer buf
      (erase-buffer)
      (org-mode)
      (insert "#+title: " title "\n\n")
      (insert "* Totals\n\n")
      (insert "| Nutrient | Total |\n|-\n")
      (dolist (nutrient my/nutrition-nutrients)
        (insert
         (format "| %s | %.2f |\n"
                 (cdr nutrient)
                 (my/nutrition--value totals (car nutrient)))))
      (org-table-align)
      (insert "\n* Meals\n\n")
      (insert "| Time | Meal | Item | Quantity | Unit | Calories |\n|-\n")
      (dolist (row rows)
        (insert
         (format "| %s | %s | %s | %s | %s | %s |\n"
                 (nth 1 row)
                 (nth 2 row)
                 (nth 3 row)
                 (nth 4 row)
                 (nth 5 row)
                 (nth 6 row))))
      (org-table-align)
      (goto-char (point-min)))
    (pop-to-buffer buf)))

(defun my/nutrition-dashboard ()
  "Open the nutrition dashboard for today."
  (interactive)
  (my/nutrition-today))

(defun my/nutrition-search ()
  "Search for a food or recipe and jump to it."
  (interactive)
  (let ((name (my/nutrition--select-entry "Find food/recipe: ")))
    (with-current-buffer (my/nutrition--buffer)
      (my/nutrition--goto-entry name)
      (pop-to-buffer (current-buffer))
      (org-show-entry)
      (recenter))))

(defun my/nutrition-refresh ()
  "Recalculate all logged meal totals from current food/recipe data.

This changes historical meal totals, so ask for confirmation first."
  (interactive)
  (when (yes-or-no-p
         "Recalculate ALL logged meals from current food/recipe data? ")
    (let ((buf (my/nutrition--buffer)))
      (with-current-buffer buf
        (let ((table (my/nutrition--meal-table)))
          (unless table
            (user-error "No Meals table"))
          (goto-char table)
          ;; Skip the header and separator rows.
          (forward-line 2)
          (while (org-at-table-p)
            (let* ((item (org-table-get-field 4))
                   (quantity (string-to-number
                              (org-table-get-field 5))))
              (when (and item
                         (not (string-empty-p (string-trim item))))
                (let ((values (my/nutrition--calculate item quantity)))
                  (dolist
                      (spec
                       '(("CALORIES" . 7)
                         ("PROTEIN"  . 8)
                         ("CARBS"    . 9)
                         ("FAT"      . 10)
                         ("FIBER"    . 11)
                         ("SUGAR"    . 12)
                         ("SODIUM"   . 13)))
                    (org-table-goto-column (cdr spec))
                    (org-table-blank-field)
                    (insert
                     (format "%.2f"
                             (my/nutrition--value
                              values
                              (car spec))))))))
            (forward-line 1)))
        (save-buffer)))
    (message "Nutrition history recalculated.")))

(defun my/nutrition-edit-food ()
  "Jump to a food entry for manual editing."
  (interactive)
  (let ((name
         (with-current-buffer (my/nutrition--buffer)
           (completing-read
            "Edit food: "
            (my/nutrition--entry-names "food")
            nil t))))
    (with-current-buffer (my/nutrition--buffer)
      (my/nutrition--goto-entry name)
      (pop-to-buffer (current-buffer))
      (org-show-entry)
      (recenter))))

(provide 'my-nutrition)
;;; my-nutrition.el ends here
