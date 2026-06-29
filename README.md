# Accessibility Super App

A Flutter application designed for accessibility, featuring voice navigation, live captioning, medication reminders, emergency SOS, and an AI Assistant.

## LLM Proxy & AI Assistant Setup

To run the AI Assistant feature, you need to spin up the local server-side LLM proxy that routes streaming requests securely to Google's Gemini API.

### 1. Proxy Server Configuration

1. **Navigate to the server directory**:
   ```bash
   cd server
   ```
2. **Configure Environment variables**:
   Duplicate `.env.example` as `.env` (already done automatically). Replace the `GEMINI_API_KEY` placeholder value with your real Gemini API key obtained from [Google AI Studio](https://aistudio.google.com/).
3. **Install dependencies**:
   ```bash
   npm install
   ```
4. **Start the server**:
   ```bash
   npm start
   ```
   The proxy server will run on `http://localhost:3000`.

### 2. Flutter Client Configuration

1. **Client Environment File**:
   Create a `.env` file at the root of the project (already generated automatically) containing the proxy URL:
   ```env
   PROXY_URL=http://localhost:3000
   ```
2. **Run the Flutter Application**:
   Ensure the proxy server is running, then run:
   ```bash
   flutter run
   ```

---

## Getting Started

This project is a starting point for a Flutter application.
For help getting started with Flutter development, view the [online documentation](https://docs.flutter.dev/).
