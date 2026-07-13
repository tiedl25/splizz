# splizz

Splizz is a cross-platform Flutter app for splitting shared costs with friends, roommates, or small groups. It is designed for everyday use when you need to record expenses quickly, keep balances clear, and avoid manual calculations.

The app is built offline first. Data is stored locally so it remains usable without a connection, and it syncs through Supabase when online. That makes it suitable for both casual one-time trips and ongoing shared households or groups.

## Screenshots

<table>
	<tr>
		<td align="center">
			<img src="assets/screenshot01.png" width="300" alt="Create a new group screen" />
			<br />
			<strong>Create a group</strong>
			<br />
			Start a new group and add members.
		</td>
		<td align="center">
			<img src="assets/screenshot02.png" width="300" alt="Choose a cover image for a group" />
			<br />
			<strong>Choose a cover image</strong>
			<br />
			Pick a cover to identify the group.
		</td>
	</tr>
	<tr>
		<td align="center">
			<img src="assets/screenshot03.png" width="300" alt="Select a member color" />
			<br />
			<strong>Set member colors</strong>
			<br />
			Use colors to keep participants easy to distinguish.
		</td>
		<td align="center">
			<img src="assets/screenshot04.png" width="300" alt="Empty group overview" />
			<br />
			<strong>Add transaction</strong>
			<br />
			Enter title, amount, date and person who payed.
		</td>
	</tr>
	<tr>
		<td align="center">
			<img src="assets/screenshot05.png" width="300" alt="Group overview with one item" />
			<br />
			<strong>Additional settings for a transaction</strong>
			<br />
			Select participating members, and split details.
		</td>
		<td align="center">
			<img src="assets/screenshot06.png" width="300" alt="Cover image selection screen" />
			<br />
			<strong>Transaction overview</strong>
			<br />
			Review balances and expense breakdowns.
		</td>
	</tr>
	<tr>
		<td align="center">
			<img src="assets/screenshot07.png" width="300" alt="Group created with members and colors" />
			<br />
			<strong>Payoff summary</strong>
			<br />
			Settle balances between participants.
		</td>
		<td align="center">
			<img src="assets/screenshot08.png" width="300" alt="Empty transactions list" />
			<br />
			<strong>Share options</strong>
			<br />
			Export a payoff overview or transaction list.
		</td>
	</tr>
	<tr>
		<td align="center">
			<img src="assets/screenshot09.png" width="300" alt="Transactions list with entries" />
			<br />
			<strong>Group dashboard</strong>
			<br />
			See member balances and recent transactions.
		</td>
		<td align="center">
			<img src="assets/screenshot10.png" width="300" alt="Add transaction dialog" />
			<br />
			<strong>Share</strong>
			<br />
			Choose with whom you want to share the list.
		</td>
	</tr>
	<tr>
		<td align="center">
			<img src="assets/screenshot11.png" width="300" alt="Payoff dialog" />
			<br />
			<strong>Member details</strong>
			<br />
			Review totals and edit a participant.
		</td>
		<td align="center">
			<img src="assets/screenshot12.png" width="300" alt="Settings screen" />
			<br />
			<strong>Editor</strong>
			<br />
			Replace the group image and title.
		</td>
	</tr>
	<tr>
		<td align="center">
			<img src="assets/screenshot13.png" width="300" alt="Current balance overview" />
			<br />
			<strong>Current balance overview</strong>
			<br />
			A compact home screen with the overall balance.
		</td>
		<td align="center">
			<img src="assets/screenshot14.png" width="300" alt="Settings screen with login and support links" />
			<br />
			<strong>Settings</strong>
			<br />
			Adjust theme, account, and app information.
		</td>
	</tr>
</table>

## Features

- Track shared expenses and record transactions
- Use the app offline-first or offline-only
- Sync data across devices when online
- Sign in with Supabase authentication
- Keep a consistent experience across mobile platforms

## WiP
- Add web support
- Take pictures of receipts to add them as transaction

## Getting Started

1. Make sure Flutter is installed.
2. Provide the required Supabase and PowerSync values in `keys.env`.
3. Run `flutter pub get`.
4. Start the app with `flutter run`.

## Release

An beta build is available on [Google Play](https://play.google.com/store/apps/details?id=de.tmc.splizz).