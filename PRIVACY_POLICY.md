# Privacy Policy for PM Captions

**Last Updated:** June 19, 2026

PM Captions ("we," "our," or "us") is dedicated to protecting your privacy. This Privacy Policy explains how we collect, use, and disclose information when you use our mobile application, PM Captions (the "App"), which is an AI Caption Generator for voiceover videos.

By using the App, you agree to the collection and use of information in accordance with this Privacy Policy.

---

## 1. Information We Collect and How We Use It

### A. Media Files and Local Data
* **What we access:** The App requires access to your device's storage/gallery to allow you to select videos and audio files for captioning, and to save the finalized captioned videos back to your gallery.
* **How we use it:**
  * **Local Processing:** We use local system tools (such as FFmpeg) to extract audio from your videos, process subtitles, and render captioned videos. This processing occurs locally on your device.
  * **Storage:** Temporary files generated during processing are stored in the App's secure local directory and are deleted when no longer needed.
* **Consent:** The App will explicitly request permissions (such as Storage or Media Gallery access) when you first attempt to select or save a video.

### B. Audio and Speech Data (Transcription)
* **What we transmit:** To generate captions, the App extracts the audio component from your selected video and sends it to the transcription provider.
* **Transcription Service:** We utilize the **Groq API** (specifically the Whisper model) for transcribing your speech into text.
* **Transmission Security:** The audio is transmitted securely over an encrypted HTTPS connection.
* **API Keys:** If you configure the App with your own API key (e.g., Groq API key), it is stored securely on your device using local storage (`SharedPreferences`) and is never sent to us or any third party, except to authenticate requests directly with the Groq API.

### C. Error Monitoring and Diagnostics
* **What we collect:** To ensure the stability of the App, we use **Sentry** for crash reporting and performance diagnostics. 
* **Data collected:** If an error occurs, Sentry may collect technical diagnostic data, including:
  * Device model and operating system version.
  * Application version and state at the time of the crash.
  * Error logs and stack traces.
* **Privacy:** We do not send your personal details, video files, or audio content to Sentry.

---

## 2. Third-Party Services

The App relies on third-party service providers to perform key functions. Below are links to their respective privacy policies:

* **Groq (Transcription Provider):** [Groq Privacy Policy](https://groq.com/privacy-policy/)
* **Sentry (Crash Reporting & Diagnostics):** [Sentry Privacy Policy](https://sentry.io/privacy/)

---

## 3. Data Retention

* **Your Videos/Audios:** We do not host or store your media files on our own servers. Video files and generated captions remain on your device unless uploaded to third-party APIs for transcription as described in Section 1B.
* **Groq Data Policy:** Audio data uploaded to Groq for transcription is processed according to Groq's data retention policies.
* **Local Storage:** You can clear local application cache and databases at any time through your device's App Settings.

---

## 4. Children's Privacy

The App is not intended for use by children under the age of 13. We do not knowingly collect personally identifiable information from children under 13. If we discover that a child under 13 has provided us with personal information, we will delete it immediately.

---

## 5. Changes to This Privacy Policy

We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date at the top. You are advised to review this Privacy Policy periodically for any changes.

---

## 6. Contact Us

If you have any questions or suggestions about our Privacy Policy, do not hesitate to contact us:

* **Email:** priyanshumallick123456@gmail.com
* **Website:** https://github.com/Priyanshu-Mallick/pm_captions
