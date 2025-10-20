#!/bin/bash


set -e

INPUT_FILE="${1:-Brainy_XML_API.md}"
OUTPUT_FILE="${2:-${INPUT_FILE%.md}.html}"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Errore: File $INPUT_FILE non trovato"
    exit 1
fi

# Estrai versione e data dal file Markdown
VERSION=$(grep -m 1 'version:' "$INPUT_FILE" | sed 's/.*"\(.*\)".*/\1/')
PUBLISH_DATE=$(grep -m 1 'publishdate:' "$INPUT_FILE" | sed 's/.*"\(.*\)".*/\1/')

echo "Conversione di $INPUT_FILE in $OUTPUT_FILE..."
echo "Versione: $VERSION"
echo "Data: $PUBLISH_DATE"

# Genera l'HTML
cat > "$OUTPUT_FILE" << EOF
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Brainy XML API Documentation v$VERSION</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            background: #f5f5f5;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 40px 60px;
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
        }
        
        /* Header con logo */
        .doc-header {
            text-align: center;
            padding: 30px 0;
            border-bottom: 3px solid #3498db;
            margin-bottom: 40px;
        }
        
        .doc-header img {
            max-width: 300px;
            height: auto;
            margin-bottom: 20px;
        }
        
        .doc-header h1 {
            color: #2c3e50;
            font-size: 2.5em;
            margin: 10px 0;
            border: none;
            padding: 0;
        }
        
        .doc-header .version-info {
            color: #7f8c8d;
            font-size: 1.1em;
            margin-top: 10px;
        }
        
        .doc-header .version-info strong {
            color: #3498db;
        }
        
        h1 {
            color: #2c3e50;
            border-bottom: 3px solid #3498db;
            padding-bottom: 10px;
            margin: 30px 0 20px 0;
            font-size: 2.2em;
        }
        
        h2 {
            color: #34495e;
            border-bottom: 2px solid #95a5a6;
            padding-bottom: 8px;
            margin: 25px 0 15px 0;
            font-size: 1.8em;
        }
        
        h3 {
            color: #7f8c8d;
            margin: 20px 0 10px 0;
            font-size: 1.4em;
        }
        
        h4 {
            color: #95a5a6;
            margin: 15px 0 10px 0;
            font-size: 1.2em;
        }
        
        p {
            margin: 10px 0;
            text-align: justify;
        }
        
        code {
            background: #f4f4f4;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: 'Courier New', monospace;
            font-size: 0.9em;
            color: #e74c3c;
        }
        
        /* Stili per XML syntax highlighting */
        pre {
            background: #282c34;
            color: #abb2bf;
            padding: 20px;
            border-radius: 5px;
            overflow-x: auto;
            margin: 15px 0;
            border-left: 4px solid #3498db;
            font-family: 'Consolas', 'Monaco', 'Courier New', monospace;
            font-size: 0.9em;
            line-height: 1.5;
        }
        
        pre code {
            background: none;
            color: inherit;
            padding: 0;
        }
        
        /* XML Syntax Highlighting */
        .xml-tag {
            color: #e06c75;
        }
        
        .xml-attribute {
            color: #d19a66;
        }
        
        .xml-value {
            color: #98c379;
        }
        
        .xml-comment {
            color: #5c6370;
            font-style: italic;
        }
        
        .xml-declaration {
            color: #c678dd;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
            font-size: 0.95em;
        }
        
        table th {
            background: #3498db;
            color: white;
            padding: 12px;
            text-align: left;
            font-weight: 600;
        }
        
        table td {
            padding: 10px 12px;
            border: 1px solid #ddd;
        }
        
        table tr:nth-child(even) {
            background: #f9f9f9;
        }
        
        table tr:hover {
            background: #f0f0f0;
        }
        
        ul, ol {
            margin: 10px 0 10px 30px;
        }
        
        li {
            margin: 5px 0;
        }
        
        strong, b {
            color: #2c3e50;
            font-weight: 600;
        }
        
        hr {
            border: none;
            border-top: 2px solid #ecf0f1;
            margin: 30px 0;
        }
        
        blockquote {
            border-left: 4px solid #3498db;
            padding-left: 20px;
            margin: 15px 0;
            color: #7f8c8d;
            font-style: italic;
        }
        
        .toc {
            background: #ecf0f1;
            padding: 20px;
            border-radius: 5px;
            margin: 20px 0;
        }
        
        .toc h2 {
            border: none;
            margin-top: 0;
        }
        
        .toc ul {
            list-style: none;
            margin-left: 0;
        }
        
        .toc a {
            color: #3498db;
            text-decoration: none;
        }
        
        .toc a:hover {
            text-decoration: underline;
        }
        
        @media print {
            body {
                background: white;
                padding: 0;
            }
            
            .container {
                box-shadow: none;
                padding: 20px;
            }
            
            pre {
                page-break-inside: avoid;
            }
            
            table {
                page-break-inside: avoid;
            }
            
            h1, h2, h3 {
                page-break-after: avoid;
            }
        }
        
        @page {
            margin: 2cm;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="doc-header">
            <img src="logo.png" alt="Brainy Logo">
            <h1>Brainy XML API Documentation</h1>
            <div class="version-info">
                <strong>Version:</strong> $VERSION | 
                <strong>Published:</strong> $PUBLISH_DATE
            </div>
        </div>
EOF

# Rimuovi le prime righe del markdown (version e publishdate) e converti
tail -n +4 "$INPUT_FILE" | pandoc -f markdown -t html --syntax-highlighting=none >> "$OUTPUT_FILE"

# Chiudi l'HTML e aggiungi lo script per evidenziare la sintassi XML
cat >> "$OUTPUT_FILE" << 'EOF'
    </div>
    <script>
        // Script per evidenziare la sintassi XML
        function highlightXML() {
            const pres = document.querySelectorAll('pre code');
            pres.forEach(code => {
                let html = code.innerHTML;

                // Attributes e Values (prima dei tag)
                html = html.replace(/([\w:-]+)=(&quot;[^&quot;]*&quot;|"[^"]*")/g,
                    '<span class="xml-attribute">$1</span>=<span class="xml-value">$2</span>');

                // Tags
                html = html.replace(/(&lt;\/?)([a-zA-Z][\w:-]*)([^&]*?)(\/?&gt;)/g,
                    '$1<span class="xml-tag">$2</span>$3$4');

                // XML declaration
                html = html.replace(/(&lt;\?xml.*?\?&gt;)/g, '<span class="xml-declaration">$1</span>');

                code.innerHTML = html;
            });
        }

        window.addEventListener('DOMContentLoaded', highlightXML);
    </script>
</body>
</html>
EOF

echo "✓ Conversione completata: $OUTPUT_FILE"

# Apri il file HTML nel browser predefinito (macOS)
open "$OUTPUT_FILE"
