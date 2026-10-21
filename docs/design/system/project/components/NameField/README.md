# NameField

The transaction name: always visible, never required. Its placeholder is the name that will be used (the selected category's name). Under it, recent names from `GET /v1/transactions/suggestions`; tapping one fills the name **and** selects its usual category. Typing filters the shortcuts, each labelled with its category.

- After saving without a name, the toast offers `Ponerle nombre`.
