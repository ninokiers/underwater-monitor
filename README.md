# Underwater Monitor 🌊🔋📷

A solar-powered, self-sustaining underwater monitoring system designed for long-term ecological observation of artificial reefs. Developed as part of a Bachelor’s Thesis in collaboration with **Marint Centrum** and **Kristianstad University**.

## 🔧 Project Components

### 📂 Root Files

\| File \| Purpose \|  
\|------\|---------\|  
\| `setup.sh` \| Master setup script that installs required packages, clones repo to both Raspberry Pi's, and configures services and timers. \|  
\| `cloud_setup.sh` \| Initializes the cloud-side server environment. \|  
\| `cloud_upload.sh` \| Handles uploading of collected video data from buoy to the cloud. \|  
\| `sensor_unit_setup.sh` \| Sets up the underwater (Pi 5) unit, configuring camera, sensors, and scheduled tasks. \|  
\| `storage_system_setup.sh` \| Prepares the buoy-based (Pi Zero) storage and upload system. \|  
\| `synchronize_video.sh` \| Script that assembles `.ts` video fragments into `.mp4` files and synchronizes them to the buoy. \|  
\| `.gitignore` \| Standard gitignore file. \|  
\| `LICENSE` \| MIT License. \|  
\| `README.md` \| This document. \|  

### 📁 `ddns/`

Scripts for maintaining a dynamic DNS address for the buoy/cloud endpoint.

\| File \| Purpose \|  
\|------\|---------\|  
\| `ddns_setup.sh` \| Installs required packages and configures DDNS updater service. \|  
\| `ddns_update.sh` \| Script to be periodically run by a timer to update IP with DNS provider. \|  

### 📁 `interval/`

Code running on the **underwater Raspberry Pi 5** to collect sensor data.

\| File \| Purpose \|  
\|------\|---------\|  
\| `interval.py` \| Main loop to periodically capture video and sensor data. \|  
\| `sensor.py` \| Interfaces with connected sensors (light and temperature). \|  

### 📁 `server/`

FastAPI/Uvicorn based web server for viewing collected video and setting configuration remotely.

\| File/Folder \| Purpose \|  
\|-------------\|---------\|  
\| `main.py` \| Web server entry point. Hosts interface for viewing logs, data, and status. \|  
\| `static/logos/` \| Institutional logos used on the frontend. \|  
\| `templates/index.html` \| Main webpage for accessing the stream. \|  
\| `templates/set_config.html` \| Web form to update system configuration parameters. \|  

---

## 🚀 Setup Instructions

### 1. On the Raspberry Pi Zero (with a clean Raspberry Pi OS Lite install)

Run the following as root or a user with sudo privileges:

\`\`\`bash
bash setup.sh
\`\`\`

This will:
- Install all necessary system packages
- Clone this GitHub repository
- Set up all relevant services (systemd timers, video sync, sensor logging)
- Deploy web server if applicable
- Schedule periodic sensor reading and video sync

> ⚠️ Make sure to run this script on the appropriate device (Pi Zero).

---

## 🧑‍🔬 Authors

- **Anh Tran** – Sensor integration and deployment  
- **Nino Kiers** – System architecture, automation, backend development  

## 🏛️ Institutions

- Kristianstad University  
- Marint Centrum  
- Lund University  

## 📜 License

MIT License – see [`LICENSE`](LICENSE) for details.
