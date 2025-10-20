#!/bin/bash
# === Raspberry Pi full SD backup ===
# Creates an image of /dev/mmcblk0 on external drive (HDD)

# --- CONFIG ---
MOUNT_POINT="/mnt/hdd1"
BACKUP_DIR="$MOUNT_POINT/shared/SNAPSHOTS_RPI3B"
LOG="$BACKUP_DIR/backup.log"
DEVICE="/dev/mmcblk0"
IMG="$BACKUP_DIR/SNAPSHOT_$(date +%Y%m%d).img"
MIN_FREE_GB=32       # Min space required (in GB) before starting
MAX_BACKUPS=5        # Keep only last N backups

# --- FUNCTIONS ---
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG"
}

# --- START ---
log "=== Starting Raspberry Pi backup process ==="

#Check if HDD is mounted
if ! mountpoint -q "$MOUNT_POINT"; then
    log "ERROR: Mount point $MOUNT_POINT is not mounted. Aborting."
    exit 1
fi

#Check free space (in GB)
FREE_GB=$(df -BG --output=avail "$MOUNT_POINT" | tail -1 | tr -dc '0-9')
if [ "$FREE_GB" -lt "$MIN_FREE_GB" ]; then
    log "ERROR: Not enough space. Free: ${FREE_GB}GB, required: ${MIN_FREE_GB}GB."
    exit 1
fi

#Start backup
log "Backup target: $IMG"
log "Free space before: ${FREE_GB}GB"

sudo dd if="$DEVICE" of="$IMG" bs=4M status=progress conv=fsync >> "$LOG" 2>&1
DD_EXIT=$?

if [ $DD_EXIT -ne 0 ]; then
    log "ERROR: dd command failed with exit code $DD_EXIT."
    exit $DD_EXIT
fi

#Verify file size sanity
SIZE_GB=$(du -BG "$IMG" | cut -f1 | tr -dc '0-9')
log "Backup finished successfully. Image size: ${SIZE_GB}GB."

#Cleanup old backups (keep last $MAX_BACKUPS)
COUNT=$(ls -1t "$BACKUP_DIR"/SNAPSHOT_*.img 2>/dev/null | wc -l)
if [ "$COUNT" -gt "$MAX_BACKUPS" ]; then
    log "Cleaning old backups (keeping last $MAX_BACKUPS)..."
    ls -1t "$BACKUP_DIR"/SNAPSHOT_*.img | tail -n +$((MAX_BACKUPS+1)) | while read OLD; do
        log "Deleting $OLD"
        rm -f "$OLD"
    done
fi

log "=== Backup process completed successfully ==="
