# Italian and Portuguese: sample for review

About 40 representative lines per language, for the founder to read before release. Every line is taken from the web catalogs (`apps/web/app/i18n/messages`) or the sign-in and claim emails (`apps/api/src/emails/sign-in.ts`), so what you read here is what ships. The app and the widget (Flutter ARB, Android strings) follow in the next step and reuse the same wording.

What to check:

- Lukitas' voice: warm, plain, positive, short sentences, as in Spanish.
- Italian uses the "tu" form.
- Portuguese is European: "telemóvel", "registar", "ligação", "palavra-passe", "Definições", the "tu" form, no "estar + gerund".
- "Lukitas" is never translated. "Lukas" and "palos" (Colombian slang) do not appear in Italian or Portuguese: "Tus lukas, por fin claras" becomes "I tuoi soldi, finalmente chiari" and "O teu dinheiro, finalmente claro".
- Placeholders (`{amount}`, `{name}`, `{daysLeft}`...) and plural rules are kept as they are.

Questions for you:

1. Italian bottom bar: "Impostazioni" is 12 letters (Spanish "Ajustes" is 7). It is the standard word; if it truncates at 360 px we can shorten it to "Opzioni".
2. Portuguese for a transaction is "movimento" (the bank word in Portugal), income is "receita" and a budget is "orçamento".
3. Italian for a budget is "budget" (what Italian finance apps say), income is "entrata".

## Landing

| key | es | it | pt |
|---|---|---|---|
| `landing.hero.annotation` | ¡Gratis, y siempre lo será! | Gratis, e lo sarà sempre! | Grátis, e vai ser sempre! |
| `landing.hero.headline` | Tus <mark>lukas</mark>, por fin claras. | I tuoi <mark>soldi</mark>, finalmente chiari. | O teu <mark>dinheiro</mark>, finalmente claro. |
| `landing.hero.description` | <lead>Lukitas es tu presupuesto, y te va a dar gusto cuidarlo.</lead> Anota un gasto en segundos y mira en qué se va cada luka. | <lead>Lukitas è il tuo budget, e ti farà piacere prendertene cura.</lead> Annota una spesa in pochi secondi e guarda dove va ogni centesimo. | <lead>Lukitas é o teu orçamento, e vais gostar de cuidar dele.</lead> Regista uma despesa em segundos e vê para onde vai cada cêntimo. |
| `landing.hero.cta` | Empieza ahora | Inizia ora | Começa agora |
| `landing.hero.cta_demo` | Pruébalo sin cuenta | Provala senza account | Experimenta sem conta |
| `landing.hero.perks` | Gratis para siempre · <github>Código abierto</github> · Sin contraseñas | Gratis per sempre · <github>Open source</github> · Senza password | Grátis para sempre · <github>Código aberto</github> · Sem palavras-passe |
| `landing.how.log.title` | Anota en segundos | Annota in pochi secondi | Regista em segundos |
| `landing.how.log.body` | Tocas ＋, escribes el monto y listo: menos de cinco segundos desde que abres la app. Lukitas lo celebra contigo. | Tocchi ＋, scrivi l'importo e fatto: meno di cinque secondi da quando apri l'app. Lukitas festeggia con te. | Tocas em ＋, escreves o valor e já está: menos de cinco segundos desde que abres a app. Lukitas celebra contigo. |
| `landing.how.budgets.title` | Presupuestos que te avisan | Budget che ti avvisano | Orçamentos que te avisam |
| `landing.how.budgets.body` | Ponle un tope a cada categoría. Las barras se llenan con lo que gastas y cambian de color antes de que te pases, no después. | Metti un tetto a ogni categoria. Le barre si riempiono con quello che spendi e cambiano colore prima che tu sfori, non dopo. | Põe um limite em cada categoria. As barras enchem com o que gastas e mudam de cor antes de te excederes, não depois. |
| `landing.faq.passwords.a` | Porque no la necesitas. Entras con un código de 6 dígitos o un enlace que te llega al correo y, si quieres, con una passkey: tu huella, tu cara o el bloqueo de tu teléfono. No hay contraseña que recordar. | Perché non ti serve. Entri con un codice di 6 cifre o con un link che ti arriva via email e, se vuoi, con una passkey: la tua impronta, il tuo viso o il blocco del telefono. Nessuna password da ricordare. | Porque não precisas dela. Entras com um código de 6 dígitos ou com uma ligação que te chega ao email e, se quiseres, com uma passkey: a tua impressão digital, a tua cara ou o bloqueio do telemóvel. Não há palavra-passe para decorar. |
| `landing.faq.privacy.a` | Tus datos viajan cifrados y nunca los vendemos ni los compartimos con anunciantes. Puedes exportarlos o borrar tu cuenta cuando quieras. El código es abierto: cualquiera puede leer el código que los maneja. | I tuoi dati viaggiano cifrati e non li vendiamo né li condividiamo mai con gli inserzionisti. Puoi esportarli o cancellare il tuo account quando vuoi. Il codice è open source: chiunque può leggere il codice che li gestisce. | Os teus dados viajam cifrados e nunca os vendemos nem os partilhamos com anunciantes. Podes exportá-los ou apagar a tua conta quando quiseres. O código é aberto: qualquer pessoa pode ler o código que os trata. |
| `landing.faq.free.a` | Sí, y lo será siempre. Lukitas es gratis y de código abierto: todo el código está en <github>GitHub</github> y cualquiera puede revisarlo. No te pedimos tarjeta. | Sì, e lo sarà sempre. Lukitas è gratis e open source: tutto il codice è su <github>GitHub</github> e chiunque può controllarlo. Non ti chiediamo la carta. | Sim, e vai ser sempre. Lukitas é grátis e de código aberto: todo o código está no <github>GitHub</github> e qualquer pessoa o pode rever. Não te pedimos cartão. |
| `roadmap.items.multi_expense.body` | «Gasté 15 mil en almuerzo y 3 mil en Uber» y quedan los dos anotados. | “Ho speso 15 per il pranzo e 3 per Uber” e restano annotate entrambe. | “Gastei 15 no almoço e 3 no Uber” e ficam as duas registadas. |

## Home, tabs and navigation

| key | es | it | pt |
|---|---|---|---|
| `home.view.transactions` | Movimientos | Movimenti | Movimentos |
| `home.view.budgets` | Categorías | Categorie | Categorias |
| `nav.home` | Inicio | Home | Início |
| `nav.insights` | Análisis | Analisi | Análise |
| `nav.recurring` | Recurrentes | Ricorrenti | Recorrentes |
| `nav.categories` | Categorías | Categorie | Categorias |
| `nav.settings` | Ajustes | Impostazioni | Definições |
| `transaction.add_expense` | Agregar gasto | Aggiungi spesa | Adicionar despesa |
| `transaction.title_expense` | Nuevo gasto | Nuova spesa | Nova despesa |
| `common.save` | Guardar | Salva | Guardar |
| `home.remaining_label` | Te quedan este mes | Ti restano questo mese | Restam-te este mês |
| `home.over_label` | Te pasaste este mes | Hai sforato questo mese | Excedeste-te este mês |
| `category_row.remaining` | Quedan {amount} | Restano {amount} | Restam {amount} |
| `category_row.over` | Te pasaste {amount} | Hai sforato di {amount} | Excedeste {amount} |
| `onboarding.budgets.title` | ¿Cuánto quieres gastar al mes? | Quanto vuoi spendere al mese? | Quanto queres gastar por mês? |
| `onboarding.budgets.lead` | Ponle un presupuesto a cada categoría. Puedes dejar alguna vacía y ponerlo después. | Dai un budget a ogni categoria. Puoi lasciarne qualcuna vuota e metterlo dopo. | Define um orçamento para cada categoria. Podes deixar alguma vazia e preenchê-la depois. |
| `home.nudge_budgets_lead` | Así Lukitas te avisa antes de que te pases. Toca una categoría y ponle un monto. | Così Lukitas ti avvisa prima che tu sfori. Tocca una categoria e metti un importo. | Assim Lukitas avisa-te antes de te excederes. Toca numa categoria e define um valor. |

## Lukitas' messages

| key | es | it | pt |
|---|---|---|---|
| `home.lukas_empty` | ¡Hola! Anota tu primer gasto con el ＋ y yo llevo la cuenta. | Ciao! Annota la tua prima spesa con il ＋ e io tengo il conto. | Olá! Regista a tua primeira despesa com o ＋ e eu faço as contas. |
| `home.lukas_over_total` | Este mes vas {over} por encima de tus presupuestos. Aquí lo tienes todo a la vista. | Questo mese sei {over} sopra i tuoi budget. Qui hai tutto sotto gli occhi. | Este mês estás {over} acima dos teus orçamentos. Aqui tens tudo à vista. |
| `lukas.first_of_day.1` | ¡«{name}» es tu primer apunte del día! Así se empieza. | «{name}» è la tua prima voce di oggi! Così si comincia. | «{name}» é o teu primeiro registo do dia! É assim que se começa. |
| `lukas.on_track.1` | Vas muy bien: te quedan {remaining} para {daysLeft, plural, one {# día} other {# días}}. | Stai andando benissimo: ti restano {remaining} per {daysLeft, plural, one {# giorno} other {# giorni}}. | Estás a ir muito bem: restam-te {remaining} para {daysLeft, plural, one {# dia} other {# dias}}. |
| `lukas.near_limit.1` | Cuidado, a {category} solo le quedan {remaining}. | Attenzione, a {category} restano solo {remaining}. | Cuidado, em {category} só restam {remaining}. |
| `lukas.over_budget.1` | En {category} vas {over} por encima. Nada grave: ya lo sabes. | In {category} sei sopra di {over}. Niente di grave: ora lo sai. | Em {category} estás {over} acima. Nada de grave: já sabes. |
| `lukas.income_received.1` | ¡Entró dinero! «{name}»: {amount} más en tu cuenta. | È entrato del denaro! «{name}»: {amount} in più sul tuo conto. | Entrou dinheiro! «{name}»: mais {amount} na tua conta. |
| `lukas.pending_paid.1` | Pagaste «{name}»: {amount}. ¡Qué alivio! | Hai pagato «{name}»: {amount}. Che sollievo! | Pagaste «{name}»: {amount}. Que alívio! |
| `lukas.month_last_day.2` | Hoy cierra el mes con {remaining} a tu favor. ¡Casi lo logras! | Oggi il mese chiude con {remaining} a tuo favore. Ce l'hai quasi fatta! | Hoje o mês fecha com {remaining} a teu favor. Quase lá! |
| `lukas.month_closed_green.2` | Cerraste con {remaining} de sobra. ¡Eso merece celebrarse! | Hai chiuso con {remaining} in più. Questo merita una festa! | Fechaste com {remaining} de sobra. Isso merece uma festa! |

## Errors

| key | es | it | pt |
|---|---|---|---|
| `errors.generic` | Algo salió mal. Inténtalo de nuevo en un momento. | Qualcosa è andato storto. Riprova tra un momento. | Algo correu mal. Tenta de novo daqui a um momento. |
| `errors.network_error` | Sin conexión. Revisa tu internet e inténtalo de nuevo. | Nessuna connessione. Controlla internet e riprova. | Sem ligação. Verifica a tua internet e tenta de novo. |
| `errors.invalid_code` | Ese código no es correcto. Revísalo e inténtalo otra vez. | Questo codice non è corretto. Controllalo e riprova. | Esse código não está correto. Verifica-o e tenta outra vez. |
| `errors.too_many_requests` | Pediste muchos códigos seguidos. Espera unos minutos e inténtalo otra vez. | Hai chiesto troppi codici di fila. Aspetta qualche minuto e riprova. | Pediste muitos códigos seguidos. Espera uns minutos e tenta outra vez. |
| `errors.sign_in_not_allowed` | Lukitas todavía no está abierto al público. Si quieres probarlo, escríbele a quien te invitó. | Lukitas non è ancora aperta al pubblico. Se vuoi provarla, scrivi a chi ti ha invitato. | Lukitas ainda não está aberta ao público. Se a quiseres experimentar, escreve a quem te convidou. |

## Sign-in

| key | es | it | pt |
|---|---|---|---|
| `sign_in.title` | Entra a Lukitas | Entra in Lukitas | Entra em Lukitas |
| `sign_in.lead` | Sin contraseñas: te mandamos un código a tu correo. | Niente password: ti mandiamo un codice via email. | Sem palavras-passe: enviamos-te um código por email. |
| `sign_in.send_code` | Enviar código | Invia codice | Enviar código |
| `passkey_offer.title` | ¿Entrar con tu huella la próxima vez? | Entrare con l'impronta la prossima volta? | Entrar com a impressão digital da próxima vez? |

## Settings

| key | es | it | pt |
|---|---|---|---|
| `settings.title` | Ajustes | Impostazioni | Definições |
| `settings.preferences` | Preferencias | Preferenze | Preferências |
| `settings.currency.hint` | Puedes cambiarla hasta tu primer movimiento. | Puoi cambiarla fino al tuo primo movimento. | Podes mudá-la até ao teu primeiro movimento. |
| `settings.delete.lead` | Borramos tu cuenta y todos tus movimientos de inmediato. Las copias de seguridad que los incluyan se borran solas en 14 días. | Cancelliamo subito il tuo account e tutti i tuoi movimenti. Le copie di sicurezza che li includono si cancellano da sole entro 14 giorni. | Apagamos a tua conta e todos os teus movimentos de imediato. As cópias de segurança que os incluem apagam-se sozinhas em 14 dias. |
| `settings.delete.action` | Eliminar mi cuenta | Elimina il mio account | Eliminar a minha conta |

## Emails

The sign-in email and the claim email (a guest saving their progress, no link).

| key | es | it | pt |
|---|---|---|---|
| `email.sign_in.subject` | Tu código de Lukitas: 123456 | Il tuo codice Lukitas: 123456 | O teu código Lukitas: 123456 |
| `email.sign_in.heading` | ¡Hola! Este es tu código para entrar | Ciao! Questo è il tuo codice per entrare | Olá! Este é o teu código para entrar |
| `email.sign_in.lead` | Escríbelo en Lukitas, o toca el botón para entrar directo. | Scrivilo in Lukitas, oppure tocca il pulsante per entrare subito. | Escreve-o em Lukitas ou toca no botão para entrares logo. |
| `email.sign_in.button` | ENTRAR A LUKITAS | ENTRA IN LUKITAS | ENTRAR EM LUKITAS |
| `email.sign_in.expiry` | El código y el enlace vencen en 10 minutos. | Il codice e il link scadono tra 10 minuti. | O código e a ligação expiram dentro de 10 minutos. |
| `email.sign_in.ignore` | Si no pediste este correo, ignóralo: nadie puede entrar sin este código. | Se non hai chiesto questa email, ignorala: nessuno può entrare senza questo codice. | Se não pediste este email, ignora-o: ninguém consegue entrar sem este código. |
| `email.claim.subject` | Tu código para guardar tu progreso: 123456 | Il tuo codice per salvare i tuoi progressi: 123456 | O teu código para guardares o teu progresso: 123456 |
| `email.claim.lead` | Escríbelo en Lukitas para guardar tu progreso con este correo. | Scrivilo in Lukitas per salvare i tuoi progressi con questa email. | Escreve-o em Lukitas para guardar o teu progresso com este email. |
