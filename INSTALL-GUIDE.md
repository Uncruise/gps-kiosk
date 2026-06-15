# GPS Kiosk — Installation Guide

**Audience:** Team members setting up a GPS Kiosk machine for the first time.
No prior Linux experience required. Follow each step in order.

---

## What You Will Need

- A computer that will become the kiosk (minimum 4 GB RAM, 32 GB storage)
- A USB stick (8 GB or larger) — **all data on it will be erased**
- Any computer (Mac, Windows, or Linux) to prepare the USB stick
- An internet connection at the kiosk machine during setup

---

## Part 1 — Prepare the USB Stick

### 1.1 Download Ubuntu

Download **Ubuntu 24.04 LTS Desktop** from the official Ubuntu website. The file ends in `.iso` and is roughly 5 GB.

### 1.2 Download Balena Etcher

Download **Balena Etcher** from `etcher.balena.io`. It runs on Mac, Windows, and Linux with no installation required.

### 1.3 Flash the USB Stick

1. Plug in your USB stick.
2. Open Balena Etcher.
3. Click **Flash from file** and select the Ubuntu `.iso` you downloaded.
4. Click **Select target** and choose your USB stick.
5. Click **Flash** and wait for it to complete (5–10 minutes).
6. Safely eject the USB stick when done.

---

## Part 2 — Install Ubuntu on the Kiosk Machine

### 2.1 Boot from USB

1. Plug the USB stick into the kiosk machine.
2. Power the machine on.
3. As soon as the screen lights up, press the boot menu key repeatedly.
   - Common keys: **F12**, **F11**, **F10**, **Esc**, or **Del** — depends on the machine.
   - The screen may briefly show which key to press (e.g. "Press F12 for Boot Menu").
4. From the boot menu, select the USB stick (may be listed as "USB" or "UEFI USB").
5. The Ubuntu installer will load. This may take a minute.

### 2.2 Install Ubuntu

1. On the welcome screen, click **Install Ubuntu**.
2. Select your language and keyboard layout. Click **Next**.
3. On the "Type of installation" screen, select **Interactive installation**. Click **Next**.
4. On the "Applications" screen, select **Default selection** (not Extended). Click **Next**.
5. On the "Install recommended proprietary software" screen — leave both boxes **unchecked**. Click **Next**.
6. On the "Disk setup" screen, select **Erase disk and install Ubuntu**.
   > **Warning:** This will delete everything on the machine's hard drive. Make sure there is nothing important on it.
7. Click **Next**, then **Install**.
8. On the "Create your account" screen:
   - **Your name:** GPS Kiosk
   - **Computer name:** `sfxgps`, `wndgps`, etc. — something that identifies the vessel
   - **Username:** `gpskiosk`
   - **Password:** choose any password — you will need it to run the setup script
   - Check **Require my password to log in**
9. Select your time zone. Click **Next**.
10. Review the summary and click **Install**.
11. Wait for installation to complete (10–20 minutes).
12. When prompted, click **Restart Now**.
13. When the screen says "Remove the installation medium and press Enter," pull out the USB stick and press **Enter**.

---

## Part 3 — First Login and Initial Setup

### 3.1 Log In

The machine will reboot and show the login screen. Log in as **gpskiosk** with the password you chose during install.

### 3.2 Connect to the Internet

Make sure the machine has an active internet connection (Ethernet cable recommended for reliability).

To check: look for a network icon in the top-right corner of the screen.

### 3.3 Open a Terminal

1. Press the **Super key** (the key with the Windows logo, or the key between Ctrl and Alt).
2. Type `terminal` and press **Enter**.
3. A black window will open. This is the terminal.

---

## Part 4 — Run the GPS Kiosk Setup

### 4.1 Download the Repo

In the terminal, type the following and press **Enter**:

```
sudo apt-get install -y git && sudo git clone https://github.com/Uncruise/gps-kiosk.git /opt/gps-kiosk
```

When prompted, enter the **gpskiosk** password you chose during Ubuntu install.

### 4.2 Run the Full Setup

```
sudo bash /opt/gps-kiosk/unix/quick-setup.sh
```

This will take **5–15 minutes** depending on internet speed. Progress messages will scroll by — this is normal.

What the script does:
- Installs Docker
- Downloads and starts the GPS Kiosk container
- Configures `gpskiosk` to auto-login on boot (no password prompt)
- Enables the systemd service so the kiosk starts on every boot
- Sets up the browser to open full-screen automatically

### 4.3 Run the GNOME Kiosk Tuning

```
sudo bash /opt/gps-kiosk/unix/kiosk-quick-setup.sh gpskiosk
```

This runs additional Ubuntu 24.04 GNOME tuning:
- Installs SSH for remote access
- Disables Wayland (required for remote desktop tools)
- Disables sleep, screen lock, and screen blanking
- Configures the GNOME keyring for passwordless autologin
- Suppresses kernel update notifications
- Schedules a daily 3 AM restart

When it asks **"Reboot now? (y/n)"** — type `n`. You will reboot in the next step.

### 4.4 Verify the Setup

At the end of each script you should see lines like:

```
✓ GPS Kiosk container started
✓ GPS Kiosk systemd services enabled
✓ GDM3 auto-login configured
✓ Screen blanking disabled
✓ Browser autostart configured (/etc/xdg/autostart/)
```

If you see any errors, take a photo of the terminal and contact Morris.

---

## Part 5 — Reboot and Confirm

### 5.1 Reboot

```
sudo reboot
```

### 5.2 What to Expect After Reboot

1. The machine restarts.
2. It automatically logs in as `gpskiosk` — no password prompt.
3. After 30–60 seconds, the browser opens full-screen showing the GPS navigation map.

If the map appears, installation is complete.

---

## Troubleshooting

### The machine boots to a login screen instead of the kiosk

Log in as `gpskiosk` and run:

```
sudo systemctl status gps-kiosk.service
```

Take a photo and contact Morris.

### The kiosk screen is blank or shows an error

Open a terminal (press **Ctrl + Alt + T**) and run:

```
docker logs gps-kiosk
```

Take a photo and contact Morris.

### The script failed partway through

Both scripts are safe to re-run. Run the same command again from Step 4.2.

### Need to access the desktop while in kiosk mode

Press **Ctrl + Alt + F2** to switch to a login terminal, or press **Ctrl + Alt + T** to open a terminal over the kiosk window.

---

## Account Summary

| Account | Purpose | Password |
|---------|---------|----------|
| `gpskiosk` | Runs the navigation display; auto-logs in on boot | Set during Ubuntu install (used only for sudo/setup) |
