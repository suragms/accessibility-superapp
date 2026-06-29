# LLM Proxy Server for Accessibility Super App

A simple Express-based server-side proxy to securely route streaming requests to Google's Gemini API without exposing credentials on-device.

## Setup Instructions

1. **Configure API Keys**:
   - Duplicate `.env.example` as `.env` (already pre-created for you).
   - Edit `.env` and replace `GEMINI_API_KEY` with a valid key generated from [Google AI Studio](https://aistudio.google.com/).

2. **Install Dependencies**:
   ```bash
   npm install
   ```

3. **Start the Proxy Server**:
   ```bash
   npm start
   ```
   The server will start on `http://localhost:3000`.
