#!/usr/bin/env python3
"""
╔══════════════════════════════════════════════════════════════════════════════════╗
║  IP-PROTECT-CONVERT - Document Conversion & IP Protection Script (Python)        ║
║  Agile Defense Systems, LLC | CAGE: 9HUP5 | dna::}{::lang™                       ║
╚══════════════════════════════════════════════════════════════════════════════════╝

Advanced document protection with:
- PDF watermarking capability
- Batch processing
- Manifest generation with hashes
- Digital signature placeholder
- Metadata extraction and preservation

Usage:
    python ip-protect-convert.py document.md
    python ip-protect-convert.py --batch ./documents/
    python ip-protect-convert.py --output ./protected/ document.md
    python ip-protect-convert.py --manifest ./protected/
    python ip-protect-convert.py --pdf document.pdf

© 2025 Agile Defense Systems, LLC. All Rights Reserved.
"""

import argparse
import hashlib
import json
import os
import shutil
import sys
from dataclasses import dataclass, field, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

# Optional imports for PDF processing
try:
    from reportlab.lib.pagesizes import letter
    from reportlab.pdfgen import canvas as reportlab_canvas
    HAS_REPORTLAB = True
except ImportError:
    HAS_REPORTLAB = False
    letter = None
    reportlab_canvas = None

try:
    from PyPDF2 import PdfReader, PdfWriter
    HAS_PYPDF2 = True
except ImportError:
    HAS_PYPDF2 = False
    PdfReader = None
    PdfWriter = None

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

VERSION = "1.0.0"
SCRIPT_NAME = "ip-protect-convert.py"

# Company Information
COMPANY_INFO = {
    "name": "Agile Defense Systems, LLC",
    "cage_code": "9HUP5",
    "duns_number": "117678011",
    "trademark": "dna::}{::lang™",
    "copyright_year": "2025",
    "website": "https://www.dnalang.dev",
    "email": "research@dnalang.dev",
}

# Supported file extensions
SUPPORTED_EXTENSIONS = {".md", ".txt", ".py", ".ts", ".sh", ".json", ".js", ".html", ".css", ".yaml", ".yml"}
PDF_EXTENSION = ".pdf"


# ═══════════════════════════════════════════════════════════════════════════════
# DATA CLASSES
# ═══════════════════════════════════════════════════════════════════════════════


@dataclass
class DocumentMetadata:
    """Metadata extracted from and embedded in documents."""

    original_file: str
    protected_file: str
    original_hash: str
    protected_hash: str
    timestamp: str
    file_size: int
    file_extension: str
    original_permissions: Optional[int] = None
    original_modified_time: Optional[str] = None
    digital_signature_placeholder: str = "SIGNATURE_PENDING"


@dataclass
class Manifest:
    """Manifest for tracking protected documents."""

    manifest_version: str = "1.0.0"
    generator: str = SCRIPT_NAME
    generator_version: str = VERSION
    company: str = field(default_factory=lambda: COMPANY_INFO["name"])
    cage_code: str = field(default_factory=lambda: COMPANY_INFO["cage_code"])
    duns_number: str = field(default_factory=lambda: COMPANY_INFO["duns_number"])
    trademark: str = field(default_factory=lambda: COMPANY_INFO["trademark"])
    generated_at: str = ""
    documents: list = field(default_factory=list)


# ═══════════════════════════════════════════════════════════════════════════════
# ASCII ART TEMPLATES
# ═══════════════════════════════════════════════════════════════════════════════

BANNER = """
╔══════════════════════════════════════════════════════════════════════════════════╗
║                                                                                  ║
║     ██╗██████╗       ██████╗ ██████╗  ██████╗ ████████╗███████╗ ██████╗████████╗ ║
║     ██║██╔══██╗      ██╔══██╗██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝ ║
║     ██║██████╔╝█████╗██████╔╝██████╔╝██║   ██║   ██║   █████╗  ██║        ██║    ║
║     ██║██╔═══╝ ╚════╝██╔═══╝ ██╔══██╗██║   ██║   ██║   ██╔══╝  ██║        ██║    ║
║     ██║██║           ██║     ██║  ██║╚██████╔╝   ██║   ███████╗╚██████╗   ██║    ║
║     ╚═╝╚═╝           ╚═╝     ╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚══════╝ ╚═════╝   ╚═╝    ║
║                                                                                  ║
║                    DOCUMENT CONVERSION & IP PROTECTION SYSTEM                    ║
║                              Python Edition v{version}                              ║
║                                                                                  ║
║                    Agile Defense Systems, LLC | CAGE: 9HUP5                      ║
║                              dna::}}{{::lang™                                      ║
║                                                                                  ║
╚══════════════════════════════════════════════════════════════════════════════════╝
""".format(
    version=VERSION
)


def get_header_template(doc_hash: str, timestamp: str, filename: str) -> str:
    """Generate the header template for text-based files."""
    return f"""╔══════════════════════════════════════════════════════════════════════════════════╗
║  AGILE DEFENSE SYSTEMS, LLC — PROPRIETARY & CONFIDENTIAL                         ║
║  CAGE: {COMPANY_INFO['cage_code']} | DUNS: {COMPANY_INFO['duns_number']} | {COMPANY_INFO['trademark']}                                     ║
╠══════════════════════════════════════════════════════════════════════════════════╣
║  Document: {filename}
║  Document Hash: {doc_hash}
║  Generated: {timestamp}
╠══════════════════════════════════════════════════════════════════════════════════╣

"""


def get_footer_template() -> str:
    """Generate the footer template for text-based files."""
    return f"""

╠══════════════════════════════════════════════════════════════════════════════════╣
║  © {COMPANY_INFO['copyright_year']} {COMPANY_INFO['name']}. All Rights Reserved.                         ║
║  This document contains trade secrets and proprietary information protected      ║
║  under 18 U.S.C. § 1836 (Defend Trade Secrets Act of 2016).                      ║
║  Unauthorized reproduction or distribution is prohibited.                        ║
╠══════════════════════════════════════════════════════════════════════════════════╣
║  {COMPANY_INFO['trademark']} is a registered trademark of {COMPANY_INFO['name']}             ║
║  Website: {COMPANY_INFO['website']} | Email: {COMPANY_INFO['email']}                    ║
╚══════════════════════════════════════════════════════════════════════════════════╝"""


def get_comment_wrapper(ext: str) -> tuple:
    """Get comment start/end based on file extension."""
    wrappers = {
        ".py": ('"""', '"""'),
        ".ts": ("/**", " */"),
        ".js": ("/**", " */"),
        ".json": ("/**", " */"),
        ".sh": ("# ", ""),
        ".html": ("<!--", "-->"),
        ".css": ("/*", "*/"),
        ".yaml": ("# ", ""),
        ".yml": ("# ", ""),
    }
    return wrappers.get(ext, ("", ""))


# ═══════════════════════════════════════════════════════════════════════════════
# UTILITY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════


def generate_sha256(file_path: Path) -> str:
    """Generate SHA-256 hash of a file."""
    sha256_hash = hashlib.sha256()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            sha256_hash.update(chunk)
    return sha256_hash.hexdigest()


def generate_sha256_from_content(content: str) -> str:
    """Generate SHA-256 hash from string content."""
    return hashlib.sha256(content.encode("utf-8")).hexdigest()


def generate_timestamp() -> str:
    """Generate ISO-8601 timestamp in UTC."""
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def timestamp_for_filename(timestamp: str) -> str:
    """Convert timestamp to filename-safe format."""
    return timestamp.replace(":", "-").replace("T", "_").replace("Z", "")


def log_info(message: str) -> None:
    """Log info message."""
    print(f"[INFO] {message}")


def log_error(message: str) -> None:
    """Log error message."""
    print(f"[ERROR] {message}", file=sys.stderr)


def log_success(message: str) -> None:
    """Log success message."""
    print(f"[SUCCESS] {message}")


def log_verbose(message: str, verbose: bool = False) -> None:
    """Log verbose message if enabled."""
    if verbose:
        print(f"[DEBUG] {message}")


# ═══════════════════════════════════════════════════════════════════════════════
# DOCUMENT PROCESSING
# ═══════════════════════════════════════════════════════════════════════════════


def extract_metadata(file_path: Path) -> dict:
    """Extract metadata from original file."""
    stat = file_path.stat()
    return {
        "original_permissions": stat.st_mode,
        "original_modified_time": datetime.fromtimestamp(
            stat.st_mtime, tz=timezone.utc
        ).isoformat(),
        "file_size": stat.st_size,
    }


def process_text_file(
    input_path: Path, output_dir: Path, verbose: bool = False
) -> Optional[DocumentMetadata]:
    """Process a text-based file with IP protection."""
    if not input_path.exists():
        log_error(f"File not found: {input_path}")
        return None

    ext = input_path.suffix.lower()
    if ext not in SUPPORTED_EXTENSIONS:
        log_error(f"Unsupported file type: {ext}")
        return None

    log_info(f"Processing: {input_path}")

    # Read original content
    with open(input_path, "r", encoding="utf-8") as f:
        original_content = f.read()

    # Generate hash and timestamp
    original_hash = generate_sha256_from_content(original_content)
    timestamp = generate_timestamp()

    log_verbose(f"  Original hash: {original_hash}", verbose)
    log_verbose(f"  Timestamp: {timestamp}", verbose)

    # Create output filename
    filename = input_path.name
    basename = input_path.stem
    output_filename = f"{basename}_protected_{timestamp_for_filename(timestamp)}{ext}"
    output_path = output_dir / output_filename

    log_verbose(f"  Output: {output_path}", verbose)

    # Build protected content
    comment_start, comment_end = get_comment_wrapper(ext)
    header = get_header_template(original_hash, timestamp, filename)
    footer = get_footer_template()

    # Handle shebang for shell scripts
    shebang = ""
    content_body = original_content
    if ext == ".sh" and original_content.startswith("#!"):
        lines = original_content.split("\n", 1)
        shebang = lines[0] + "\n"
        content_body = lines[1] if len(lines) > 1 else ""

    # Build protected content based on file type
    if ext == ".py":
        protected_content = f'{comment_start}\n{header}{comment_end}\n\n{content_body}\n\n{comment_start}\n{footer}\n{comment_end}'
    elif ext in {".ts", ".js", ".json", ".css"}:
        # Wrap header/footer in comments
        header_lines = "\n".join(f" * {line}" for line in header.strip().split("\n"))
        footer_lines = "\n".join(f" * {line}" for line in footer.strip().split("\n"))
        protected_content = f"{comment_start}\n{header_lines}\n */\n\n{content_body}\n\n/*\n{footer_lines}\n{comment_end}"
    elif ext == ".sh":
        header_lines = "\n".join(f"# {line}" for line in header.strip().split("\n"))
        footer_lines = "\n".join(f"# {line}" for line in footer.strip().split("\n"))
        protected_content = f"{shebang}#\n{header_lines}\n#\n\n{content_body}\n\n#\n{footer_lines}"
    elif ext == ".html":
        protected_content = f"{comment_start}\n{header}\n{comment_end}\n\n{content_body}\n\n{comment_start}\n{footer}\n{comment_end}"
    elif ext in {".yaml", ".yml"}:
        header_lines = "\n".join(f"# {line}" for line in header.strip().split("\n"))
        footer_lines = "\n".join(f"# {line}" for line in footer.strip().split("\n"))
        protected_content = f"{header_lines}\n\n{content_body}\n\n{footer_lines}"
    else:
        # Default: plain text
        protected_content = f"{header}{content_body}{footer}"

    # Ensure output directory exists
    output_dir.mkdir(parents=True, exist_ok=True)

    # Write protected file
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(protected_content)

    # Preserve permissions
    try:
        original_mode = input_path.stat().st_mode
        output_path.chmod(original_mode)
    except OSError:
        pass

    # Generate hash of protected file
    protected_hash = generate_sha256(output_path)

    log_success(f"Protected file created: {output_path}")
    log_verbose(f"  Protected hash: {protected_hash}", verbose)

    # Extract and return metadata
    original_meta = extract_metadata(input_path)

    return DocumentMetadata(
        original_file=str(input_path),
        protected_file=str(output_path),
        original_hash=original_hash,
        protected_hash=protected_hash,
        timestamp=timestamp,
        file_size=original_meta["file_size"],
        file_extension=ext,
        original_permissions=original_meta["original_permissions"],
        original_modified_time=original_meta["original_modified_time"],
    )


def process_pdf(
    input_path: Path, output_dir: Path, verbose: bool = False
) -> Optional[DocumentMetadata]:
    """Process a PDF file with watermarking."""
    log_info(f"Processing PDF: {input_path}")

    # Check if required libraries are available
    if not HAS_REPORTLAB:
        log_error(
            "PDF watermarking requires 'reportlab' package. Install with: pip install reportlab"
        )
    if not HAS_PYPDF2:
        log_error(
            "PDF watermarking requires 'PyPDF2' package. Install with: pip install PyPDF2"
        )

    if not HAS_REPORTLAB or not HAS_PYPDF2:
        log_error("PDF processing unavailable. Creating metadata-only entry.")
        # Create a metadata entry without actual watermarking
        original_hash = generate_sha256(input_path)
        timestamp = generate_timestamp()
        original_meta = extract_metadata(input_path)

        return DocumentMetadata(
            original_file=str(input_path),
            protected_file=str(input_path) + " (watermarking unavailable)",
            original_hash=original_hash,
            protected_hash=original_hash,
            timestamp=timestamp,
            file_size=original_meta["file_size"],
            file_extension=".pdf",
            original_permissions=original_meta.get("original_permissions"),
            original_modified_time=original_meta.get("original_modified_time"),
        )

    # Generate hash and timestamp
    original_hash = generate_sha256(input_path)
    timestamp = generate_timestamp()

    # Create output filename
    basename = input_path.stem
    output_filename = f"{basename}_protected_{timestamp_for_filename(timestamp)}.pdf"
    output_path = output_dir / output_filename

    # Ensure output directory exists
    output_dir.mkdir(parents=True, exist_ok=True)

    # Create watermark PDF
    import io

    watermark_buffer = io.BytesIO()
    c = reportlab_canvas.Canvas(watermark_buffer, pagesize=letter)
    width, height = letter

    # Add watermark text
    c.setFont("Helvetica", 8)
    c.setFillColorRGB(0.5, 0.5, 0.5, 0.3)

    # Header watermark
    c.drawString(
        50, height - 30, f"AGILE DEFENSE SYSTEMS, LLC — CAGE: {COMPANY_INFO['cage_code']}"
    )
    c.drawString(50, height - 42, f"{COMPANY_INFO['trademark']} — {timestamp}")

    # Footer watermark
    c.drawString(
        50, 30, f"© {COMPANY_INFO['copyright_year']} {COMPANY_INFO['name']} — CONFIDENTIAL"
    )
    c.drawString(50, 18, f"Hash: {original_hash[:32]}...")

    # Diagonal watermark
    c.saveState()
    c.translate(width / 2, height / 2)
    c.rotate(45)
    c.setFont("Helvetica", 40)
    c.setFillColorRGB(0.9, 0.9, 0.9, 0.2)
    c.drawCentredString(0, 0, "PROPRIETARY")
    c.restoreState()

    c.save()
    watermark_buffer.seek(0)

    # Apply watermark to each page
    watermark_pdf = PdfReader(watermark_buffer)
    watermark_page = watermark_pdf.pages[0]

    reader = PdfReader(str(input_path))
    writer = PdfWriter()

    for page in reader.pages:
        page.merge_page(watermark_page)
        writer.add_page(page)

    # Add metadata
    writer.add_metadata(
        {
            "/Title": f"Protected Document - {input_path.name}",
            "/Author": COMPANY_INFO["name"],
            "/Subject": "IP Protected Document",
            "/Creator": f"{SCRIPT_NAME} v{VERSION}",
            "/Producer": COMPANY_INFO["trademark"],
            "/Keywords": f"CAGE:{COMPANY_INFO['cage_code']}, Hash:{original_hash}",
        }
    )

    # Write output
    with open(output_path, "wb") as f:
        writer.write(f)

    protected_hash = generate_sha256(output_path)
    log_success(f"Protected PDF created: {output_path}")

    original_meta = extract_metadata(input_path)

    return DocumentMetadata(
        original_file=str(input_path),
        protected_file=str(output_path),
        original_hash=original_hash,
        protected_hash=protected_hash,
        timestamp=timestamp,
        file_size=original_meta["file_size"],
        file_extension=".pdf",
        original_permissions=original_meta.get("original_permissions"),
        original_modified_time=original_meta.get("original_modified_time"),
    )


def process_batch(
    input_dir: Path, output_dir: Path, include_pdf: bool = False, verbose: bool = False
) -> list:
    """Process all supported files in a directory."""
    if not input_dir.is_dir():
        log_error(f"Directory not found: {input_dir}")
        return []

    log_info(f"Batch processing directory: {input_dir}")
    log_info(f"Output directory: {output_dir}")

    documents = []
    processed = 0
    skipped = 0

    # Process text files
    for ext in SUPPORTED_EXTENSIONS:
        for file_path in input_dir.glob(f"*{ext}"):
            result = process_text_file(file_path, output_dir, verbose)
            if result:
                documents.append(result)
                processed += 1
            else:
                skipped += 1

    # Process PDFs if requested
    if include_pdf:
        for file_path in input_dir.glob("*.pdf"):
            result = process_pdf(file_path, output_dir, verbose)
            if result:
                documents.append(result)
                processed += 1
            else:
                skipped += 1

    log_info(f"Processed: {processed} files")
    log_info(f"Skipped: {skipped} files")

    return documents


# ═══════════════════════════════════════════════════════════════════════════════
# MANIFEST GENERATION
# ═══════════════════════════════════════════════════════════════════════════════


def generate_manifest(output_dir: Path, documents: list) -> None:
    """Generate a manifest JSON file."""
    manifest_path = output_dir / "manifest.json"

    manifest = Manifest(
        generated_at=generate_timestamp(), documents=[asdict(doc) for doc in documents]
    )

    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(asdict(manifest), f, indent=2)

    log_success(f"Manifest generated: {manifest_path}")


def regenerate_manifest(output_dir: Path, verbose: bool = False) -> None:
    """Regenerate manifest from existing protected files."""
    if not output_dir.is_dir():
        log_error(f"Directory not found: {output_dir}")
        return

    log_info(f"Regenerating manifest for: {output_dir}")

    documents = []
    timestamp = generate_timestamp()

    for ext in SUPPORTED_EXTENSIONS | {PDF_EXTENSION}:
        for file_path in output_dir.glob(f"*{ext}"):
            if "manifest" in file_path.name.lower():
                continue

            file_hash = generate_sha256(file_path)
            meta = extract_metadata(file_path)

            doc = DocumentMetadata(
                original_file="(original not tracked)",
                protected_file=str(file_path),
                original_hash="(not available)",
                protected_hash=file_hash,
                timestamp=timestamp,
                file_size=meta["file_size"],
                file_extension=file_path.suffix,
                original_permissions=meta.get("original_permissions"),
                original_modified_time=meta.get("original_modified_time"),
            )
            documents.append(doc)
            log_verbose(f"  Added: {file_path.name}", verbose)

    generate_manifest(output_dir, documents)


# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════


def main() -> None:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="IP Protection Document Conversion Tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=f"""
Examples:
  {SCRIPT_NAME} document.md
  {SCRIPT_NAME} --batch ./documents/
  {SCRIPT_NAME} --output ./protected/ document.md
  {SCRIPT_NAME} --manifest ./protected/
  {SCRIPT_NAME} --pdf document.pdf

© {COMPANY_INFO['copyright_year']} {COMPANY_INFO['name']}
CAGE: {COMPANY_INFO['cage_code']} | {COMPANY_INFO['trademark']}
""",
    )

    parser.add_argument("input", nargs="?", help="Input file or directory")
    parser.add_argument("-o", "--output", help="Output directory")
    parser.add_argument(
        "-b", "--batch", action="store_true", help="Batch process directory"
    )
    parser.add_argument(
        "-m", "--manifest", action="store_true", help="Generate/update manifest only"
    )
    parser.add_argument(
        "-p", "--pdf", action="store_true", help="Include PDF processing"
    )
    parser.add_argument("-v", "--verbose", action="store_true", help="Verbose output")
    parser.add_argument("--version", action="store_true", help="Show version")

    args = parser.parse_args()

    if args.version:
        print(f"{SCRIPT_NAME} version {VERSION}")
        print(f"© {COMPANY_INFO['copyright_year']} {COMPANY_INFO['name']}")
        print(f"CAGE: {COMPANY_INFO['cage_code']} | {COMPANY_INFO['trademark']}")
        return

    print(BANNER)

    if not args.input:
        parser.print_help()
        return

    input_path = Path(args.input)
    output_dir = Path(args.output) if args.output else input_path.parent / "protected"

    if args.manifest:
        regenerate_manifest(input_path if input_path.is_dir() else output_dir, args.verbose)
    elif args.batch:
        documents = process_batch(input_path, output_dir, args.pdf, args.verbose)
        if documents:
            generate_manifest(output_dir, documents)
    elif input_path.suffix.lower() == PDF_EXTENSION:
        result = process_pdf(input_path, output_dir, args.verbose)
        if result:
            generate_manifest(output_dir, [result])
    elif input_path.is_file():
        result = process_text_file(input_path, output_dir, args.verbose)
        if result:
            generate_manifest(output_dir, [result])
    elif input_path.is_dir():
        log_error("For directories, use --batch flag")
        return
    else:
        log_error(f"File or directory not found: {input_path}")
        return

    print()
    log_info("IP protection complete")
    print("╔══════════════════════════════════════════════════════════════════╗")
    print(f"║  © {COMPANY_INFO['copyright_year']} {COMPANY_INFO['name']}                       ║")
    print(f"║  CAGE: {COMPANY_INFO['cage_code']} | {COMPANY_INFO['trademark']}                                   ║")
    print("╚══════════════════════════════════════════════════════════════════╝")


if __name__ == "__main__":
    main()
