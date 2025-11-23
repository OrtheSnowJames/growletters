<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { socketService } from '$lib/socket';
	import { Card, Input, LoadingButton, StatusMessage, LobbyLink } from '$lib/components';

	let playerName = '';
	let lobbyCode = '';
	let isCreatingLobby = false;
	let isJoiningLobby = false;
	let error = '';
	let success = '';
	let lobbyLink = '';
	let allowedToBeHost = true;
	let sab = new SharedArrayBuffer(1024);
	const sabView = new Uint8Array(sab);

	async function createLobby() {
		if (!playerName.trim()) {
			error = 'Please enter your name';
			return;
		}

		isCreatingLobby = true;
		error = '';
		success = '';

		try {
			// Create lobby via backend API first
			const response = await fetch('http://localhost:3000/create-lobby', {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json'
				}
			});

			if (!response.ok) {
				throw new Error(`HTTP error! status: ${response.status}`);
			}

			const data = await response.json();

			// Connect to socket with lobby info
			const lobbyData = await socketService.connect(data.lobbyId.toString(), playerName, true);

			// Generate lobby link
			lobbyLink = `${window.location.origin}/landing?code=${lobbyData.lobbyCode}`;

			success = `Lobby created! Code: ${lobbyData.lobbyCode}`;

			// Store lobby info and redirect to lobby page
			localStorage.setItem('lobbyId', lobbyData.lobbyId);
			localStorage.setItem('lobbyCode', lobbyData.lobbyCode);
			localStorage.setItem('playerName', playerName);
			localStorage.setItem('isHost', 'true');

			setTimeout(() => {
				goto('/');
			}, 2000);
		} catch (err) {
			console.error('Error creating lobby:', err);
			error = err instanceof Error ? err.message : 'Failed to create lobby';
		} finally {
			isCreatingLobby = false;
		}
	}

	async function joinLobby() {
		if (!playerName.trim() || !lobbyCode.trim()) {
			error = 'Please enter your name and lobby code';
			return;
		}

		isJoiningLobby = true;
		error = '';
		success = '';

		try {
			// First, validate the lobby code by trying to get lobby info
			const response = await fetch(`http://localhost:3000/lobby/${lobbyCode}`);

			if (!response.ok) {
				throw new Error('Invalid lobby code');
			}

			const data = await response.json();
			success = `Joining lobby ${data.lobbyCode}...`;

			// Connect to socket with lobby info
			const lobbyData = await socketService.connect(data.lobbyId.toString(), playerName, false);

			// Store lobby info and redirect to lobby page
			localStorage.setItem('lobbyId', lobbyData.lobbyId);
			localStorage.setItem('lobbyCode', lobbyData.lobbyCode);
			localStorage.setItem('playerName', playerName);
			localStorage.setItem('isHost', 'false');

			setTimeout(() => {
				goto('/');
			}, 2000);
		} catch (err) {
			console.error('Error joining lobby:', err);
			error = err instanceof Error ? err.message : 'Failed to join lobby';
		} finally {
			isJoiningLobby = false;
		}
	}

	onMount(() => {
		// Clear any existing lobby data when landing
		localStorage.removeItem('lobbyId');
		localStorage.removeItem('lobbyCode');
		localStorage.removeItem('playerName');
		localStorage.removeItem('isHost');

		// Check for lobby code in URL parameters
		const urlParams = new URLSearchParams(window.location.search);
		const codeFromUrl = urlParams.get('code');
		if (codeFromUrl) {
			lobbyCode = codeFromUrl.toUpperCase();
			allowedToBeHost = false;
		}
	});
</script>

<div class="min-h-screen bg-slate-900 text-slate-100 flex items-center justify-center p-4">
	<div class="max-w-md w-full space-y-8">
		<!-- Header -->
		<div class="text-center">
			<h1 class="text-4xl font-mono text-green-400 font-bold tracking-wider mb-2">
				grow_some_letters
			</h1>
			{#if allowedToBeHost}
			<p class="text-lg text-slate-300">Choose your role to get started</p>
			{:else}
			<p class="text-lg text-slate-300">Enter your name</p>
			{/if}
		</div>

		<!-- Main Content -->
		<div class="space-y-6">
			<!-- Player Name Input -->
			<Input
				bind:value={playerName}
				label="Your Name"
				placeholder="Enter your name"
				required={true}
			/>

			<!-- Host Section -->
			{#if allowedToBeHost}
			<Card title="Host a Game" subtitle="Create a new lobby and invite players to join">
				<LoadingButton
					loading={isCreatingLobby}
					disabled={isCreatingLobby || isJoiningLobby}
					variant="success"
					fullWidth={true}
					loadingText="Creating Lobby..."
					onClick={createLobby}
				>
					Create Lobby
				</LoadingButton>

				<!-- Lobby Link Section (shown after lobby creation) -->
				{#if lobbyLink}
					<div class="mt-4">
						<LobbyLink
							{lobbyCode}
							label="Share this link with players:"
							copyButtonLabel="Copy"
							copyButtonVariant="blue"
						/>
					</div>
				{/if}
			</Card>
			{/if}
			<!-- Player Section -->
			<Card title="Join a Game" subtitle="Enter a lobby code to join an existing game">
				<div class="space-y-4">
					<Input
						bind:value={lobbyCode}
						label="Lobby Code"
						placeholder="Enter 6-digit code"
						maxlength={6}
						variant={error && !playerName.trim() ? 'error' : 'default'}
						errorText={error && !playerName.trim() ? error : ''}
					/>

					<LoadingButton
						loading={isJoiningLobby}
						disabled={isCreatingLobby || isJoiningLobby}
						variant="blue"
						fullWidth={true}
						loadingText="Joining Lobby..."
						onClick={joinLobby}
					>
						Join Lobby
					</LoadingButton>
				</div>
			</Card>

			<!-- Status Messages -->
			<StatusMessage
				type="error"
				message={error}
				show={!!error}
				dismissible={true}
				onDismiss={() => (error = '')}
			/>

			<StatusMessage
				type="success"
				message={success}
				show={!!success}
				dismissible={true}
				onDismiss={() => (success = '')}
			/>
		</div>

		<!-- Footer -->
		<div class="text-center text-slate-500 text-sm">
			<p>This is just a demo of what the landing page could look like. ;)</p>
		</div>
	</div>
</div>

<style>
	input[type='text'] {
		text-transform: uppercase;
	}
</style>
