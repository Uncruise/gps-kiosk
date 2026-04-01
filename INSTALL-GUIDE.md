# GPS Kiosk — Installation Guide

**Audience:** Team members setting up a GPS Kiosk machine for the first time.
No prior Linux experience required. Follow each step in order.

---

## What You Will Need

- A computer that will become the kiosk (minimum 4 GB RAM, 32 GB storage)
- A USB stick (8 GB or larger) — **all data on it will be erased**
- A separate Windows PC to prepare the USB stick
- An internet connection at the kiosk machine during setup
- The passwords recorded in the section below

---

## Passwords

Fill these in before you start. Keep this document somewhere safe.

| Account | Username | Password |
|---------|----------|----------|
| Admin (management) | `gpsadmin` | ________________________ |
| Kiosk (auto-login) | `gpskiosk` | ________________________ |

> Both accounts can share the same password if preferred.
> The **admin** account is for logging in to manage the machine.
> The **kiosk** account logs in automatically on boot and runs the navigation display.

---

## Part 1 — Prepare the USB Stick (on a Windows PC)

### 1.1 Download Ubuntu

1. Open a web browser and go to the official Ubuntu website.
2. Download **Ubuntu 24.04 LTS Desktop** (the file ends in `.iso`, roughly 5 GB).

### 1.2 Download Rufus

1. Go to the Rufus website and download the latest version.
2. No installation needed — it runs directly as a `.exe` file.

### 1.3 Flash the USB Stick

1. Plug in your USB stick.
2. Open Rufus.
3. Under **Device**, select your USB stick from the dropdown.
4. Under **Boot selection**, click **SELECT** and choose the Ubuntu `.iso` file you downloaded.
5. Leave all other settings at their defaults.
6. Click **START**.
7. If Rufus asks which write mode to use, select **Write in ISO Image mode** and click OK.
8. Wait for it to complete (5–10 minutes). Click **CLOSE** when done.
9. Safely eject the USB stick.

---

## Part 2 — Install Ubuntu on the Kiosk Machine

### 2.1 Boot from USB

1. Plug the USB stick into the kiosk machine.
2. Power the machine on.
3. As soon as the screen lights up, press the boot menu key repeatedly.
   - Common keys: **F12**, **F11**, **F10**, **Esc**, or **Del** — it depends on the machine.
   - The screen may briefly show which key to press (e.g. "Press F12 for Boot Menu").
4. From the boot menu, select the USB stick (it may be listed as "USB" or "UEFI USB").
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
   - **Your name:** GPS Admin
   - **Computer name:** gps-kiosk-01 *(or a name that identifies the machine)*
   - **Username:** `gpsadmin`
   - **Password:** *(enter the admin password from the table above)*
   - Check **Require my password to log in**
9. Select your time zone. Click **Next**.
10. Review the summary and click **Install**.
11. Wait for installation to complete (10–20 minutes).
12. When prompted, click **Restart Now**.
13. When the screen says "Remove the installation medium and press Enter," pull out the USB stick and press **Enter**.

---

## Part 3 — First Login and Initial Setup

### 3.1 Log In

1. The machine will reboot and show the login screen.
2. Log in as **gpsadmin** with the admin password.

### 3.2 Connect to the Internet

Make sure the machine has an active internet connection (Ethernet cable recommended for reliability).

To check: look for a network icon in the top-right corner of the screen. If using Wi-Fi, click it and connect to your network.

### 3.3 Open a Terminal

A terminal is where you type commands. To open one:

1. Press the **Windows key** (or click the grid icon in the bottom-left).
2. Type `terminal` and press **Enter**.
3. A black window will open. This is the terminal.

---

## Part 4 — Run the GPS Kiosk Setup Script

This single command installs everything and configures the machine as a kiosk. Type it carefully — or copy and paste it.

### 4.1 Download the Setup Script

In the terminal, type the following and press **Enter**:

```
sudo apt-get install -y git && sudo git clone https://github.com/Uncruise/gps-kiosk.git /opt/gps-kiosk
```

When prompted, enter the **admin password** (`gpsadmin`'s password).

### 4.2 Run the Setup

Type the following command, replacing the placeholder with the password from your table:

```
sudo bash /opt/gps-kiosk/unix/ubuntu-kiosk-setup.sh --password YOUR_PASSWORD_HERE
```

Example (if your password is `Anchor2024`):

```
sudo bash /opt/gps-kiosk/unix/ubuntu-kiosk-setup.sh --password Anchor2024
```

> This script will:
> - Install Docker and all required software
> - Create the `gpsadmin` and `gpskiosk` user accounts
> - Download and start the GPS Kiosk navigation software
> - Configure the machine to boot directly into the kiosk display
> - Disable screen sleep and lock screens
>
> It will take **5–15 minutes** depending on internet speed. You will see progress messages scrolling by — this is normal.

### 4.3 Verify the Setup

At the end of the script, you will see a verification table like this:

```
  ✓  Docker daemon running
  ✓  GPS Kiosk container running
  ✓  Signal K responding
  ✓  gps-kiosk.service enabled
  ✓  start-gps-kiosk.sh executable
  ✓  Kiosk user exists
  ✓  sudoers file present
  ✓  Browser binary found
```

All items should show **✓**. If any show **✗**, take a photo of the terminal and contact Morris.

---

## Part 5 — Reboot and Confirm Kiosk Mode

### 5.1 Reboot

In the terminal, type:

```
sudo reboot
```

### 5.2 What to Expect After Reboot

1. The machine restarts.
2. It automatically logs in as `gpskiosk` — **no password prompt will appear**.
3. After about 30–60 seconds, the browser opens full-screen showing the GPS navigation map.
4. The display should show the Freeboard-SK navigation interface.

If the map appears, the installation is complete.

---

## Troubleshooting

### The machine boots to a login screen instead of the kiosk

Log in as `gpsadmin` and run:

```
sudo systemctl status gps-kiosk.service
```

Take a photo of the output and contact Morris.

### The kiosk screen is blank or shows an error

Open a terminal (press **Ctrl + Alt + T**) and run:

```
docker logs gps-kiosk
```

Take a photo of the output and contact Morris.

### The script failed partway through

The script is safe to run again. Re-run the same command from Step 4.2 — it will skip steps that are already complete.

### Need to access the desktop while in kiosk mode

Press **Ctrl + Alt + F2** to switch to a login terminal, or press **Ctrl + Alt + T** to try opening a terminal over the kiosk window. Log in as `gpsadmin`.

---

## Summary of Accounts

| Account | Purpose | Notes |
|---------|---------|-------|
| `gpsadmin` | Administration and management | Use this to make changes, run updates, or troubleshoot |
| `gpskiosk` | Kiosk display (auto-login) | Runs the navigation browser on boot; do not log into this account manually |
