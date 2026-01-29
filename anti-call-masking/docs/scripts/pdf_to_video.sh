#!/bin/bash
# Convert PDF presentations to MP4 videos
# Each slide is displayed for 5 seconds

set -e

DOCS_DIR="/Users/AbiolaOgunsakin1/Anti_Call-Masking/anti-call-masking/docs"
TEMP_DIR=$(mktemp -d)
SLIDE_DURATION=5  # seconds per slide

convert_pdf_to_mp4() {
    local pdf_path="$1"
    local mp4_path="$2"
    local name=$(basename "$pdf_path" .pdf)
    local img_dir="$TEMP_DIR/$name"

    echo "Converting: $name"
    mkdir -p "$img_dir"

    # Convert PDF to images (1920x1080)
    echo "  Extracting slides..."
    pdftoppm -png -r 150 -scale-to-x 1920 -scale-to-y 1080 "$pdf_path" "$img_dir/slide"

    # Count slides
    local slide_count=$(ls "$img_dir"/slide-*.png 2>/dev/null | wc -l)
    echo "  Found $slide_count slides"

    if [ "$slide_count" -eq 0 ]; then
        echo "  ERROR: No slides extracted!"
        return 1
    fi

    # Create video using ffmpeg
    echo "  Creating video (${SLIDE_DURATION}s per slide)..."
    ffmpeg -y -framerate 1/$SLIDE_DURATION -pattern_type glob -i "$img_dir/slide-*.png" \
        -c:v libx264 -pix_fmt yuv420p -r 30 \
        -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" \
        "$mp4_path" 2>/dev/null

    echo "  Created: $mp4_path"

    # Cleanup
    rm -rf "$img_dir"
}

echo "=== Converting PDFs to MP4 Videos ==="
echo ""

# Training presentations
echo "Training Presentations:"
for pdf in "$DOCS_DIR/training/presentations/exports/pdf"/*.pdf; do
    if [ -f "$pdf" ]; then
        name=$(basename "$pdf" .pdf)
        mp4="$DOCS_DIR/training/presentations/exports/mp4/${name}.mp4"
        convert_pdf_to_mp4 "$pdf" "$mp4"
    fi
done

echo ""
echo "NCC Executive Presentations:"
for pdf in "$DOCS_DIR/presentations/exports/pdf"/*.pdf; do
    if [ -f "$pdf" ]; then
        name=$(basename "$pdf" .pdf)
        mp4="$DOCS_DIR/presentations/exports/mp4/${name}.mp4"
        convert_pdf_to_mp4 "$pdf" "$mp4"
    fi
done

# Cleanup temp directory
rm -rf "$TEMP_DIR"

echo ""
echo "=== Video Conversion Complete ==="
