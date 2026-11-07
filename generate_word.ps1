# Script para generar Informe_Pruebas_Caja_Blanca_Panama_Historica.docx
$ErrorActionPreference = "Stop"

$outputDocx = "c:\Users\Daniel Ubarte\Documents\Proyecto_ISA\Informe_Pruebas_Caja_Blanca_Panama_Historica.docx"
$tempDir = Join-Path $env:TEMP ("docx_gen_" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $tempDir "_rels") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $tempDir "word") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $tempDir "word\_rels") -Force | Out-Null

# 1. [Content_Types].xml
$contentTypes = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>
'@
[System.IO.File]::WriteAllText((Join-Path $tempDir "[Content_Types].xml"), $contentTypes, [System.Text.Encoding]::UTF8)

# 2. _rels/.rels
$pkgRels = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>
'@
[System.IO.File]::WriteAllText((Join-Path $tempDir "_rels\.rels"), $pkgRels, [System.Text.Encoding]::UTF8)

# 3. word/_rels/document.xml.rels
$docRels = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>
'@
[System.IO.File]::WriteAllText((Join-Path $tempDir "word\_rels\document.xml.rels"), $docRels, [System.Text.Encoding]::UTF8)

# 4. word/styles.xml
$styles = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/>
        <w:sz w:val="22"/>
        <w:szCs w:val="22"/>
        <w:color w:val="222222"/>
      </w:rPr>
    </w:rPrDefault>
    <w:pPrDefault>
      <w:pPr>
        <w:spacing w:line="276" w:lineRule="auto" w:after="160"/>
      </w:pPr>
    </w:pPrDefault>
  </w:docDefaults>
  <w:style w:type="paragraph" w:styleId="Normal" w:default="1">
    <w:name w:val="Normal"/>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Title">
    <w:name w:val="Title"/>
    <w:pPr>
      <w:spacing w:before="0" w:after="100"/>
      <w:jc w:val="center"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
      <w:b/>
      <w:sz w:val="48"/>
      <w:color w:val="003366"/>
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Subtitle">
    <w:name w:val="Subtitle"/>
    <w:pPr>
      <w:spacing w:before="0" w:after="240"/>
      <w:jc w:val="center"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
      <w:i/>
      <w:sz w:val="26"/>
      <w:color w:val="555555"/>
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading1">
    <w:name w:val="heading 1"/>
    <w:pPr>
      <w:spacing w:before="360" w:after="160"/>
      <w:keepNext/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
      <w:b/>
      <w:sz w:val="32"/>
      <w:color w:val="003366"/>
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading2">
    <w:name w:val="heading 2"/>
    <w:pPr>
      <w:spacing w:before="240" w:after="120"/>
      <w:keepNext/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
      <w:b/>
      <w:sz w:val="26"/>
      <w:color w:val="005599"/>
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading3">
    <w:name w:val="heading 3"/>
    <w:pPr>
      <w:spacing w:before="180" w:after="80"/>
      <w:keepNext/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
      <w:b/>
      <w:sz w:val="23"/>
      <w:color w:val="333333"/>
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="CodeBlock">
    <w:name w:val="Code Block"/>
    <w:pPr>
      <w:shd w:val="clear" w:color="auto" w:fill="F4F6F8"/>
      <w:spacing w:line="240" w:lineRule="auto" w:before="40" w:after="40"/>
      <w:ind w:left="180" w:right="180"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Consolas" w:hAnsi="Consolas"/>
      <w:sz w:val="17"/>
      <w:color w:val="1A202C"/>
    </w:rPr>
  </w:style>
</w:styles>
'@
[System.IO.File]::WriteAllText((Join-Path $tempDir "word\styles.xml"), $styles, [System.Text.Encoding]::UTF8)

# Funciones auxiliares para construcción de Document XML
function Xml-Escape([string]$s) {
    if ([string]::IsNullOrEmpty($s)) { return "" }
    return $s.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace('"', "&quot;").Replace("'", "&apos;")
}

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
[void]$sb.AppendLine('<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">')
[void]$sb.AppendLine('<w:body>')

function Add-P([string]$text, [string]$style = "Normal", [bool]$bold = $false, [bool]$italic = $false, [string]$color = "", [string]$align = "") {
    $pPr = ""
    if ($style -ne "Normal") {
        $pPr += "<w:pStyle w:val=`"$style`"/>"
    }
    if ($align -ne "") {
        $pPr += "<w:jc w:val=`"$align`"/>"
    }
    if ($pPr -ne "") { $pPr = "<w:pPr>$pPr</w:pPr>" }

    $rPr = ""
    if ($bold) { $rPr += "<w:b/>" }
    if ($italic) { $rPr += "<w:i/>" }
    if ($color -ne "") { $rPr += "<w:color w:val=`"$color`"/>" }
    if ($rPr -ne "") { $rPr = "<w:rPr>$rPr</w:rPr>" }

    $escaped = Xml-Escape $text
    [void]$sb.AppendLine("<w:p>$pPr<w:r>$rPr<w:t xml:space=`"preserve`">$escaped</w:t></w:r></w:p>")
}

function Add-CodeLine([string]$text) {
    $escaped = Xml-Escape $text
    [void]$sb.AppendLine("<w:p><w:pStyle w:val=`"CodeBlock`"/><w:r><w:rFonts w:ascii=`"Consolas`" w:hAnsi=`"Consolas`"/><w:sz w:val=`"16`"/><w:t xml:space=`"preserve`">$escaped</w:t></w:r></w:p>")
}

function Add-Table([string[]]$headers, [System.Collections.ArrayList]$rows, [int[]]$widths, [bool]$isCompact = $false) {
    [void]$sb.AppendLine('<w:tbl>')
    [void]$sb.AppendLine('  <w:tblPr>')
    [void]$sb.AppendLine('    <w:tblW w:w="0" w:type="auto"/>')
    [void]$sb.AppendLine('    <w:tblBorders>')
    [void]$sb.AppendLine('      <w:top w:val="single" w:sz="6" w:space="0" w:color="003366"/>')
    [void]$sb.AppendLine('      <w:bottom w:val="single" w:sz="6" w:space="0" w:color="003366"/>')
    [void]$sb.AppendLine('      <w:left w:val="none"/>')
    [void]$sb.AppendLine('      <w:right w:val="none"/>')
    [void]$sb.AppendLine('      <w:insideH w:val="single" w:sz="4" w:space="0" w:color="E2E8F0"/>')
    [void]$sb.AppendLine('      <w:insideV w:val="none"/>')
    [void]$sb.AppendLine('    </w:tblBorders>')
    [void]$sb.AppendLine('  </w:tblPr>')

    # Table Grid
    [void]$sb.AppendLine('  <w:tblGrid>')
    foreach ($w in $widths) {
        [void]$sb.AppendLine("    <w:gridCol w:w=`"$w`"/>")
    }
    [void]$sb.AppendLine('  </w:tblGrid>')

    # Header Row
    [void]$sb.AppendLine('  <w:tr>')
    [void]$sb.AppendLine('    <w:trPr><w:tblHeader/><w:cantSplit/></w:trPr>')
    for ($i = 0; $i -lt $headers.Length; $i++) {
        $w = $widths[$i]
        $hText = Xml-Escape $headers[$i]
        [void]$sb.AppendLine("    <w:tc>")
        [void]$sb.AppendLine("      <w:tcPr><w:tcW w:w=`"$w`" w:type=`"dxa`"/><w:shd w:val=`"clear`" w:color=`"auto`" w:fill=`"003366`"/><w:tcMar><w:top w:w=`"120`" w:type=`"dxa`"/><w:bottom w:w=`"120`" w:type=`"dxa`"/><w:left w:w=`"100`" w:type=`"dxa`"/><w:right w:w=`"100`" w:type=`"dxa`"/></w:tcMar></w:tcPr>")
        [void]$sb.AppendLine("      <w:p><w:pPr><w:spacing w:before=`"40`" w:after=`"40`"/><w:jc w:val=`"center`"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val=`"19`"/><w:color w:val=`"FFFFFF`"/></w:rPr><w:t xml:space=`"preserve`">$hText</w:t></w:r></w:p>")
        [void]$sb.AppendLine("    </w:tc>")
    }
    [void]$sb.AppendLine('  </w:tr>')

    # Data Rows
    $rowIndex = 0
    foreach ($row in $rows) {
        $fill = if ($rowIndex % 2 -eq 1) { "F8FAFC" } else { "FFFFFF" }
        [void]$sb.AppendLine('  <w:tr>')
        [void]$sb.AppendLine('    <w:trPr><w:cantSplit/></w:trPr>')
        for ($i = 0; $i -lt $row.Length; $i++) {
            $w = $widths[$i]
            $cellText = Xml-Escape $row[$i]
            $cellAlign = if ($i -eq 0 -or $i -eq ($row.Length - 1)) { "center" } else { "left" }
            $isStatus = ($i -eq ($row.Length - 1))
            $statusColor = if ($cellText -eq "Aprobada") { "1B5E20" } elseif ($cellText -eq "Fallida") { "B71C1C" } else { "333333" }
            $statusBold = if ($isStatus -or $i -eq 0) { "<w:b/>" } else { "" }
            $fontSize = if ($isCompact) { "17" } else { "19" }

            [void]$sb.AppendLine("    <w:tc>")
            [void]$sb.AppendLine("      <w:tcPr><w:tcW w:w=`"$w`" w:type=`"dxa`"/><w:shd w:val=`"clear`" w:color=`"auto`" w:fill=`"$fill`"/><w:tcMar><w:top w:w=`"100`" w:type=`"dxa`"/><w:bottom w:w=`"100`" w:type=`"dxa`"/><w:left w:w=`"100`" w:type=`"dxa`"/><w:right w:w=`"100`" w:type=`"dxa`"/></w:tcMar></w:tcPr>")
            [void]$sb.AppendLine("      <w:p><w:pPr><w:spacing w:before=`"30`" w:after=`"30`"/><w:jc w:val=`"$cellAlign`"/></w:pPr><w:r><w:rPr>$statusBold<w:sz w:val=`"$fontSize`"/><w:color w:val=`"$statusColor`"/></w:rPr><w:t xml:space=`"preserve`">$cellText</w:t></w:r></w:p>")
            [void]$sb.AppendLine("    </w:tc>")
        }
        [void]$sb.AppendLine('  </w:tr>')
        $rowIndex++
    }
    [void]$sb.AppendLine('</w:tbl>')
}

# --- PORTADA Y METADATOS ---
Add-P "INFORME ACADÉMICO DE ASEGURAMIENTO DE LA CALIDAD Y PRUEBAS DE CAJA BLANCA" "Title" $true $false "003366" "center"
Add-P "Evaluación Estructural de Caminos Lógicos y Cobertura Automatizada en Flutter / Dart" "Subtitle" $false $true "555555" "center"

# Cuadro informativo de metadatos
$metaHeaders = @("Parámetro Académico", "Detalle de Configuración")
$metaRows = New-Object System.Collections.ArrayList
[void]$metaRows.Add(@("Proyecto de Software", "Panamá Histórica (App Móvil Educativa)"))
[void]$metaRows.Add(@("Ecosistema y Lenguaje", "Flutter 3.x / Dart 3.x (SDK >= 3.0.0 < 4.0.0)"))
[void]$metaRows.Add(@("Módulos Funcionales Evaluados", "1) Narración de Contenidos (TTSService) | 2) Historiador IA (Motor RAG BM25)"))
[void]$metaRows.Add(@("Módulos Complementarios", "Autenticación (AuthService) y Persistencia de Lectura (ProgressService)"))
[void]$metaRows.Add(@("Casos de Prueba Ejecutados", "25 Casos de Caja Blanca (TC-01 al TC-25) en test/white_box_25_suite_test.dart"))
[void]$metaRows.Add(@("Estado de las Pruebas", "25 Aprobadas / 0 Fallidas (100% de éxito empírico)"))
[void]$metaRows.Add(@("Análisis Estático (Linter)", "flutter analyze: 0 errores, 0 advertencias"))
Add-Table $metaHeaders $metaRows @(3500, 6500)

Add-P "" "Normal"

# --- SECCIÓN 1: INTRODUCCIÓN ---
Add-P "1. Introducción y Fundamentos de Caja Blanca" "Heading1"
Add-P "El Aseguramiento de la Calidad de Software (Software Quality Assurance - SQA) comprende un conjunto sistemático de actividades orientadas a garantizar que los productos de software satisfagan los requerimientos funcionales, de robustez y de fiabilidad especificados. Dentro de las metodologías formales de Verificación y Validación (V&V), las pruebas de caja blanca (White-Box Testing o pruebas estructurales) permiten examinar la arquitectura y el código interno del sistema a nivel de instrucciones, caminos de decisión, condiciones compuestas, valores de frontera y bloques de manejo de excepciones."
Add-P "El presente informe documenta formalmente la planificación, análisis exhaustivo, diseño y ejecución empírica de 25 casos de prueba de caja blanca desarrollados sobre el proyecto real Panamá Histórica. Cada caso fue concebido analizando directamente las líneas de código fuente en Dart, garantizando una trazabilidad fidedigna entre los caminos lógicos y los resultados obtenidos en el marco de pruebas oficial de Flutter."

# --- SECCIÓN 2: INSPECCIÓN DEL PROYECTO ---
Add-P "2. Inspección Técnica del Proyecto e Identificación de Módulos" "Heading1"
Add-P "2.1. Distinción entre Módulos de Contenido Histórico y Módulos Funcionales de Software" "Heading2"
Add-P "Una consideración metodológica crítica es evitar la confusión entre el contenido histórico curricular y los módulos funcionales del software:"
Add-P "• Módulos Históricos de Contenido: Corresponden a los temas de estudio provistos a los estudiantes (ejemplo: 'Panamá Contemporánea', enfocado en los sucesos de la gesta patriótica del 9 de enero de 1964 y los tratados Chiari-Kennedy)."
Add-P "• Módulos Funcionales de Software: Corresponden a las capas arquitectónicas y servicios del sistema que ejecutan la lógica de procesamiento (control de audio y síntesis de voz, motor de recuperación documental RAG, validación de autenticación y persistencia de estado)."

Add-P "2.2. Estado Real de Implementación en el Código Fuente" "Heading2"
Add-P "Tras una inspección directa de los archivos fuente en lib/ y assets/, se determinó con precisión el estado de cada componente sin inventar clases ni métodos inexistentes:"

$inspHeaders = @("Funcionalidad / Módulo", "Archivos Reales en lib/", "Estado de Implementación", "Hallazgo Técnico en el Código")
$inspRows = New-Object System.Collections.ArrayList
[void]$inspRows.Add(@("Narración de Contenidos", "services/tts_service.dart`nwidgets/tts_floating_bar.dart", "Implementado", "Servicio ChangeNotifier con integración a flutter_tts, temporizador Timer.periodic, reanudación contextual y captura de excepciones de hardware."))
[void]$inspRows.Add(@("Historiador IA (Motor RAG)", "services/rag/retrieval_engine.dart`nservices/rag/rag_response_generator.dart`nservices/ai_service.dart", "Implementado", "Motor RAG local estricto con índice documental en JSON (183 fragmentos del libro de Wendy Tribaldos). Aplica BM25 modificado, filtrado de stopwords y política de abstención cuando no hay evidencia."))
[void]$inspRows.Add(@("Autenticación y Acceso", "services/auth_service.dart`nscreens/auth/login_screen.dart`nscreens/auth/register_screen.dart", "Implementado en memoria", "Validación estricta de campos vacíos, control de excepciones por credenciales incompletas y mutación de sesión en memoria; preparado para Firebase."))
[void]$inspRows.Add(@("Contenido Panamá Contemporánea", "modules/contemporanea/contemporanea_content.dart`nmodules/contemporanea/contemporanea_screen.dart", "Implementado", "Consulta de 4 escenas históricas, galería de imágenes locales existentes y visor de PDF con persistencia de lectura."))
[void]$inspRows.Add(@("Persistencia y Descargas", "services/progress_service.dart`nservices/download_service.dart`nservices/content_service.dart", "Implementado", "Persistencia real con SharedPreferences para registro de IDs vistos, última página de PDF leída y streams de progreso de descarga."))
[void]$inspRows.Add(@("Progreso y Analítica", "screens/progress/progress_screen.dart`nmodels/progress_model.dart", "Parcialmente implementado", "La interfaz gráfica visualiza métricas reales de los materiales locales vistos, pero utiliza objetos mock para estadísticas globales de grado."))
[void]$inspRows.Add(@("Realidad Aumentada (AR) y Unity", "N/A", "No existente", "El proyecto no contiene dependencias de AR ni exportables de Unity en el árbol de código (prohibido explícitamente incluir AR o Unity)."))
Add-Table $inspHeaders $inspRows @(2200, 2600, 2200, 3600) $true

Add-P "" "Normal"

# --- SECCIÓN 3: ANÁLISIS DE CAMINOS LÓGICOS ---
Add-P "3. Análisis de Caminos Lógicos y Justificación de los 25 Casos" "Heading1"
Add-P "3.1. Rutas Lógicas en el Módulo de Narración de Contenidos (TTSService)" "Heading2"
Add-P "En services/tts_service.dart, se analizaron los siguientes elementos estructurales:"
Add-P "• Condición Compuesta Inicial con OR (Línea 89): if (!_isTTSEnabled || text.trim().isEmpty) return;. Si cualquiera de las dos condiciones es verdadera, la ejecución se interrumpe inmediatamente sin invocar el canal nativo de FlutterTts (cubierto en TC-02 y TC-03). Si ambas son falsas, progresa al flujo de reproducción (TC-01)."
Add-P "• Operador Ternario de Asignación Límite (Línea 95): _totalDurationSeconds = durationSeconds > 0 ? durationSeconds : 135;. Evalúa la condición de frontera numérica. Si la duración es menor o igual a cero, se asigna el valor nominal de seguridad de 135 segundos (TC-04)."
Add-P "• Guarda de Estado en Pausa (Línea 141): if (!_isPlaying) return;. Evita operaciones redundantes de pausa si el reproductor ya se encuentra inactivo (TC-05)."
Add-P "• Condición Compuesta con AND para Reanudación (Línea 97): if (_isPaused && _currentSceneId == sceneId). Si el estado está en pausa y el identificador de escena coincide con la escena actual, reanuda el audio conservando el tiempo transcurrido (TC-06). Si la escena solicitada es diferente, la rama AND evalúa como falsa, descartando la reanudación y reiniciando el cronómetro a cero (TC-07)."
Add-P "• Temporizador Periódico y Expiración (Líneas 128-136): if (_elapsedSeconds < _totalDurationSeconds) avanza el contador cada segundo y normaliza el progreso (TC-08). En el momento en que se alcanza el límite temporal, la rama else ejecuta stop(), reseteando el estado (TC-09)."
Add-P "• Tolerancia a Fallos y Manejo de Excepciones (Líneas 121-123): Bloque try-catch alrededor de _flutterTts.speak(text). Si el hardware de audio o canal nativo genera PlatformException, el error se captura sin interrumpir abruptamente la aplicación (TC-10)."

Add-P "3.2. Rutas Lógicas en el Módulo Historiador IA (Motor RAG Documental)" "Heading2"
Add-P "En services/rag/retrieval_engine.dart y services/rag/rag_response_generator.dart:"
Add-P "• Normalización y Filtrado de Palabras Vacías (Líneas 56-78): Limpieza de tildes ('á','é','í','ó','ú','ü','ñ'), caracteres especiales y descarte de términos pertenecientes al conjunto _spanishStopwords (TC-11)."
Add-P "• Guarda de Consulta sin Palabras Sustantivas (Línea 95): if (queryTokens.isEmpty) return RetrievalResult.insufficient(...);. Si una pregunta contiene únicamente stopwords o signos, se abstiene de inmediato (TC-12)."
Add-P "• Algoritmo de Puntuación BM25 y Cobertura (Líneas 162-230): En preguntas documentadas sobre el 9 de enero y Balboa High School, la puntuación supera el umbral minThreshold = 3.2 y ratio de cobertura >= 0.35 (TC-13)."
Add-P "• Bonificación por Frase Exacta (Líneas 189-191): if (normalizedQuery.length >= 6 && cleanChunkText.contains(normalizedQuery)) score += 4.5;. Otorga una ventaja competitiva al fragmento que contiene la frase textual (TC-14)."
Add-P "• Política de Abstención Estricta por Términos Desconocidos (Líneas 134-138): if (unknownRatio >= 0.3 || (unknownTokens.isNotEmpty && queryTokens.length <= 3)). Si la pregunta involucra entidades ajenas a los documentos (e.g. Batalla de Waterloo o redes neuronales), el motor se abstiene estrictamente (TC-15 y TC-16)."
Add-P "• Descarte de Preguntas Hiper-Genéricas (Línea 179): Exige al menos un nonGenericMatches > 0, descartando consultas que solo contienen palabras como 'año', 'tiempo', 'día' o 'momento' (TC-17)."
Add-P "• Estructuración Pedagógica y Citas Documentales (Líneas 33-83 en rag_response_generator.dart): Emite el mensaje oficial de abstención cuando no hay suficiente evidencia (TC-18) o sintetiza la explicación histórica extrayendo título de documento y número de página verificables (TC-19)."
Add-P "• Historial de Conversación en AIService (Líneas 39-96 en ai_service.dart): Registra la pregunta del estudiante y la respuesta generada en la lista _messages manteniendo el orden temporal y coherencia de roles (TC-20)."

Add-P "3.3. Rutas Lógicas en Autenticación y Persistencia (TC-21 a TC-25)" "Heading2"
Add-P "• Validación Compuesta de Credenciales en signIn() (Línea 21 en auth_service.dart): if (email.isEmpty || password.isEmpty). Permite autenticación válida (TC-21) o dispara Exception si alguno de los campos obligatorios falta (TC-22)."
Add-P "• Validación Compuesta de Registro en register() (Línea 36 en auth_service.dart): if (email.isEmpty || password.isEmpty || name.isEmpty) throw Exception('Todos los campos son obligatorios.'); (TC-23)."
Add-P "• Cierre de Sesión Seguro (Línea 61 en auth_service.dart): _currentUser = null;, garantizando que isAuthenticated sea false tras invocar signOut() (TC-24)."
Add-P "• Persistencia de Progreso en ProgressService (Líneas 16-52): Almacena de forma confiable en SharedPreferences el progreso de lectura y la última página leída del PDF (TC-25)."

# --- SECCIÓN 4: TABLA DE LOS 25 CASOS ---
Add-P "4. Matriz Completa de los 25 Casos de Prueba de Caja Blanca" "Heading1"
Add-P "La siguiente tabla resume los 25 casos de prueba de caja blanca ejecutados en el proyecto. Cada caso fue implementado y verificado en la suite automatizada test/white_box_25_suite_test.dart, registrando evidencia real en cada aserción:"

$tcHeaders = @("ID", "Módulo Funcional", "Descripción del Camino Lógico", "Entradas Utilizadas", "Resultado Esperado", "Resultado Obtenido", "Estado")
$tcRows = New-Object System.Collections.ArrayList

[void]$tcRows.Add(@("TC-01", "Narración de Contenidos", "Camino feliz: speak() con TTS activo, texto válido y sin pausa previa", "text = 'El 9 de enero...'`nsceneId = 'escena_01'`nduration = 120s", "isPlaying: true, isPaused: false, sceneId: 'escena_01', elapsed: 0s", "Variables actualizadas, audio nativo invocado satisfactoriamente", "Aprobada"))
[void]$tcRows.Add(@("TC-02", "Narración de Contenidos", "Validación: text.trim().isEmpty evalúa true en condición OR (Línea 89)", "text = '   '`nsceneId = 'escena_01'", "Retorno inmediato sin mutar estado; isPlaying: false, text: ''", "Retorno inmediato verificado; reproductor permanece inactivo", "Aprobada"))
[void]$tcRows.Add(@("TC-03", "Narración de Contenidos", "Guarda: !_isTTSEnabled evalúa true tras toggleTTS(false)", "toggleTTS(false)`nspeak('Texto...')", "Retorno inmediato; no inicia reproducción ni altera el temporizador", "Ejecución abortada limpiamente; isPlaying: false", "Aprobada"))
[void]$tcRows.Add(@("TC-04", "Narración de Contenidos", "Frontera: Operador ternario durationSeconds > 0 ? durationSeconds : 135", "text = 'Texto...'`ndurationSeconds = 0", "Asignación de duración por defecto nominal (totalDuration: 135s)", "totalDurationSeconds asignado con valor de reserva 135s", "Aprobada"))
[void]$tcRows.Add(@("TC-05", "Narración de Contenidos", "Guarda de estado: if (!_isPlaying) return; en pausa activa vs inactiva", "1) pause() inactivo`n2) speak() y luego pause()", "Inactivo: sin mutación.`nActivo: isPlaying: false, isPaused: true", "Comportamiento exacto verificado en ambos estados", "Aprobada"))
[void]$tcRows.Add(@("TC-06", "Narración de Contenidos", "Reanudación: _isPaused && _currentSceneId == sceneId evalúa true", "Pausa en 'escena_01'`nspeak('...', sceneId: 'escena_01')", "Reanuda narración; isPlaying: true, isPaused: false, preserva elapsed", "Reanudación exitosa sin reinicio del tiempo transcurrido", "Aprobada"))
[void]$tcRows.Add(@("TC-07", "Narración de Contenidos", "Descarte reanudación: _currentSceneId != sceneId evalúa rama AND como false", "Pausa en 'escena_01'`nspeak('...', sceneId: 'escena_02')", "Descarta reanudación; reinicia elapsed: 0, asigna sceneId: 'escena_02'", "Estado reseteado para nueva escena; sceneId: 'escena_02'", "Aprobada"))
[void]$tcRows.Add(@("TC-08", "Narración de Contenidos", "Temporizador: Avance _elapsedSeconds < _totalDurationSeconds", "duration = 10s`navance de 4s con fakeAsync", "elapsedSeconds: 4, progress: 0.4 normalizado", "Contador avanzó exactamente 4s; progress normalizado a 0.4", "Aprobada"))
[void]$tcRows.Add(@("TC-09", "Narración de Contenidos", "Expiración tiempo: Rama else -> stop() al llegar a duración total", "duration = 3s`navance de 4s con fakeAsync", "Invocación de stop(); isPlaying: false, elapsed: 0s, progress: 0.0", "Narración finalizada y variables reseteadas automáticamente", "Aprobada"))
[void]$tcRows.Add(@("TC-10", "Narración de Contenidos", "Manejo excepción: Bloque catch(e) ante fallo de hardware en speak()", "Mock flutter_tts lanzando PlatformException en 'speak'", "Excepción capturada en catch; app no colapsa y conserva integridad", "Error interceptado en log sin propagar fallo fatal", "Aprobada"))

[void]$tcRows.Add(@("TC-11", "Historiador IA", "Normalización léxica: Sustitución de tildes y descarte de stopwords", "text = '¿Quién marchó el 9 de Enero de 1964?'", "Texto limpio: 'quien marcho el 9 de enero de 1964'. Tokens: marcho, enero, 1964", "Signos y tildes removidos; stopwords filtradas con éxito", "Aprobada"))
[void]$tcRows.Add(@("TC-12", "Historiador IA", "Guarda: queryTokens.isEmpty ante consulta solo de palabras vacías", "query = '¿Cómo era cuando fue sobre este?'", "Retorno de RetrievalResult.insufficient(); hasSufficientEvidence: false", "hasSufficientEvidence: false, chunks.isEmpty: true", "Aprobada"))
[void]$tcRows.Add(@("TC-13", "Historiador IA", "Recuperación documental: Superación de umbral BM25 (>= 3.2)", "query = '¿Por qué marcharon los estudiantes a la Escuela de Balboa?'", "hasSufficientEvidence: true, fragmentos de Wendy Tribaldos recuperados", "Puntuación superior a 3.2; fragmentos devueltos con páginas", "Aprobada"))
[void]$tcRows.Add(@("TC-14", "Historiador IA", "Bonificación: Coincidencia de frase exacta de 2+ términos (score += 4.5)", "query = 'acuerdo chiari kennedy'", "Puntuación aumentada por boost de frase exacta en texto del fragmento", "Top score superior a 10.0 con fragmentos altamente pertinentes", "Aprobada"))
[void]$tcRows.Add(@("TC-15", "Historiador IA", "Abstención estricta: unknownRatio >= 0.3 ante tema fuera de dominio", "query = '¿Quién ganó la batalla de Waterloo y en qué año?'", "Abstención inmediata; hasSufficientEvidence: false, chunks: []", "Resultado insuficiente; motor se abstiene sin falsas coincidencias", "Aprobada"))
[void]$tcRows.Add(@("TC-16", "Historiador IA", "Abstención estricta: Conceptos tecnológicos no cubiertos en acervo histórico", "query = '¿Cómo entrenar una red neuronal convolucional en Python?'", "Abstención por ausencia de términos en índice documental; chunks: []", "Filtro de términos desconocidos activado; abstención estricta", "Aprobada"))
[void]$tcRows.Add(@("TC-17", "Historiador IA", "Filtro términos genéricos: nonGenericMatches == 0 sin sustantivos clave", "query = '¿Qué ocurrió en el momento y tiempo de aquel día?'", "Descarte de fragmentos por falta de sustantivos temáticos específicos", "Resultado insuficiente generado por falta de términos específicos", "Aprobada"))
[void]$tcRows.Add(@("TC-18", "Historiador IA", "Generador pedagógico: Rama !hasSufficientEvidence en generate()", "retrievalResult = RetrievalResult.insufficient(...)", "isAbstention: true, mensaje oficial de abstención, references: []", "isAbstention: true y mensaje pedagógico oficial emitido", "Aprobada"))
[void]$tcRows.Add(@("TC-19", "Historiador IA", "Generador pedagógico: Rama con evidencia y extracción de citas y páginas", "query = '¿En qué consistía el acuerdo Chiari Kennedy?'", "isAbstention: false, texto educativo y referencias con título y página", "Respuesta estructurada generada con citas bibliográficas válidas", "Aprobada"))
[void]$tcRows.Add(@("TC-20", "Historiador IA", "Integración de conversación: Adición a historial en AIService.askHistorian()", "question = '¿Por qué marcharon los institutores a Balboa?'", "Historial incrementa en 2 mensajes (uno 'user' y uno 'ai' con referencias)", "Historial incrementó en 2 elementos; roles y contenidos consistentes", "Aprobada"))

[void]$tcRows.Add(@("TC-21", "Autenticación", "Validación credenciales completas en AuthService.signIn()", "email = 'estudiante@academia.pa'`npassword = 'password123'", "Retorna UserModel autenticado; isAuthenticated: true", "Usuario autenticado en memoria con el correo ingresado", "Aprobada"))
[void]$tcRows.Add(@("TC-22", "Autenticación", "Rechazo por campos vacíos: if (email.isEmpty || password.isEmpty)", "email = ''`npassword = ''", "Lanza Exception('Por favor ingrese correo y contraseña.')", "Excepción interceptada con el mensaje exacto esperado", "Aprobada"))
[void]$tcRows.Add(@("TC-23", "Autenticación", "Validación compuesta de registro: omisión de nombre obligatorio", "name = ''`nemail = 'nuevo@pa.edu'`npassword = '123'`ngrade = '11°'", "Lanza Exception('Todos los campos son obligatorios.')", "Excepción interceptada; registro rechazado por omisión de nombre", "Aprobada"))
[void]$tcRows.Add(@("TC-24", "Autenticación", "Cierre de sesión seguro: _currentUser = null en AuthService.signOut()", "Invocación a signOut() tras sesión previa activa", "currentUser: null, isAuthenticated: false", "Sesión anulada; usuario desconectado satisfactoriamente", "Aprobada"))
[void]$tcRows.Add(@("TC-25", "Persistencia", "Almacenamiento y recuperación en ProgressService (SharedPreferences)", "markMaterialAsViewed('contemporanea_01')`nsetPdfLastPage('contemporanea_01', 12)", "getViewedMaterialIds() contiene ID, getPdfLastPage() retorna 12", "Datos persistidos y recuperados fielmente desde almacenamiento mock", "Aprobada"))

Add-Table $tcHeaders $tcRows @(900, 1500, 1900, 1600, 1900, 1900, 1000) $true

Add-P "" "Normal"

# --- SECCIÓN 5: EVIDENCIAS DE EJECUCIÓN ---
Add-P "5. Evidencias de Ejecución y Métricas de Calidad" "Heading1"
Add-P "5.1. Ejecución Automatizada de la Suite de Pruebas" "Heading2"
Add-P "Las pruebas se ejecutaron mediante la herramienta oficial flutter test sobre el archivo test/white_box_25_suite_test.dart:"
Add-CodeLine "flutter test test/white_box_25_suite_test.dart"
Add-CodeLine "00:00 +0: loading test/white_box_25_suite_test.dart"
Add-CodeLine "00:00 +1: TC-01: Reproducción inicial de narración con parámetros válidos"
Add-CodeLine "00:00 +2: TC-02: Rechazo de reproducción con texto vacío o compuesto solo por espacios"
Add-CodeLine "00:00 +3: TC-03: Bloqueo de reproducción cuando la narración está deshabilitada"
Add-CodeLine "00:00 +4: TC-04: Asignación de duración por defecto cuando durationSeconds <= 0"
Add-CodeLine "00:00 +5: TC-05: Pausa de narración activa vs invocación redundante de pausa"
Add-CodeLine "00:00 +6: TC-06: Reanudación de narración pausada para la misma escena"
Add-CodeLine "00:00 +7: TC-07: Cambio de escena durante la pausa (desestimar reanudación)"
Add-CodeLine "00:00 +8: TC-08: Avance del tiempo simulado en Timer.periodic y cálculo de progreso"
Add-CodeLine "00:00 +9: TC-09: Finalización automática por expiración de duración total"
Add-CodeLine "00:00 +10: TC-10: Manejo y captura de excepción al fallar el canal de hardware en speak()"
Add-CodeLine "00:00 +11: TC-11: Normalización de texto y descarte de acentos y caracteres especiales"
Add-CodeLine "00:00 +12: TC-12: Consulta compuesta exclusivamente por stopwords (sin tokens sustantivos)"
Add-CodeLine "00:00 +13: TC-13: Recuperación de fragmentos con evidencia suficiente (9 de enero y Balboa)"
Add-CodeLine "00:00 +14: TC-14: Bonificación por coincidencia de frase exacta de 2 o más palabras"
Add-CodeLine "00:00 +15: TC-15: Abstención estricta ante conceptos desconocidos fuera de dominio (Batalla de Waterloo)"
Add-CodeLine "00:00 +16: TC-16: Abstención estricta ante preguntas de tecnología contemporánea no documentada"
Add-CodeLine "00:00 +17: TC-17: Descarte de consultas compuestas únicamente por términos genéricos"
Add-CodeLine "00:00 +18: TC-18: Generador pedagógico - Respuesta de abstención cuando no hay evidencia"
Add-CodeLine "00:00 +19: TC-19: Generador pedagógico - Respuesta documentada y extracción de referencias"
Add-CodeLine "00:00 +20: TC-20: Flujo integral de consulta en AIService y persistencia en historial"
Add-CodeLine "00:01 +21: TC-21: Autenticación exitosa en AuthService.signIn() con datos completos"
Add-CodeLine "00:02 +22: TC-22: Rechazo de autenticación en AuthService.signIn() por campos vacíos"
Add-CodeLine "00:03 +23: TC-23: Rechazo de registro en AuthService.register() por omisión de nombre o correo"
Add-CodeLine "00:03 +24: TC-24: Cierre de sesión en AuthService.signOut() y anulación de currentUser"
Add-CodeLine "00:04 +25: TC-25: Persistencia y recuperación del progreso de lectura en ProgressService"
Add-CodeLine "00:04 +25: All tests passed!"

Add-P "5.2. Análisis Estático con el Analizador Oficial de Dart" "Heading2"
Add-P "Se verificó la integridad del proyecto mediante flutter analyze:"
Add-CodeLine "flutter analyze"
Add-CodeLine "Analyzing Proyecto_ISA..."
Add-CodeLine "No issues found! (ran in 1.2s)"

# --- SECCIÓN 6: CONCLUSIONES ---
Add-P "6. Conclusiones y Recomendaciones Académicas" "Heading1"
Add-P "1. Cobertura Estructural de Alta Fidelidad: La actividad de pruebas de caja blanca permitió corroborar que las decisiones lógicas críticas (operadores ternarios, bifurcaciones compuestas con cortocircuito AND/OR y control de excepciones nativas) operan según los requisitos de ingeniería previstos."
Add-P "2. Confiabilidad y Determinismo del Historiador IA: Se demostró que el motor RAG interno no alucina ni produce información falsa ante preguntas fuera del alcance curricular gracias al filtro estricto de vocabulario y el cálculo ponderado BM25 con umbral mínimo."
Add-P "3. Resiliencia en Audio y Control Temporal: El módulo de narración TTS demostró no presentar fugas de recursos (leaks de Timer) y tolera desconexiones o fallos en el canal de síntesis nativo sin provocar cierres inesperados en la app."
Add-P "4. Recomendaciones para Pruebas Futuras: Al integrar Firebase Auth y Cloud Firestore, se sugiere incorporar pruebas unitarias con librerías mock especializadas (fake_cloud_firestore). Asimismo, para el visor de PDFs se aconseja instrumentar pruebas de integración (integration_test) sobre dispositivos Android e iOS para validar el renderizado del motor nativo."

# Configuración de página (Letter, márgenes de 1 pulgada = 1440 dxa)
[void]$sb.AppendLine('  <w:sectPr>')
[void]$sb.AppendLine('    <w:pgSz w:w="12240" w:h="15840" w:orient="portrait"/>')
[void]$sb.AppendLine('    <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="720" w:footer="720" w:gutter="0"/>')
[void]$sb.AppendLine('  </w:sectPr>')

[void]$sb.AppendLine('</w:body>')
[void]$sb.AppendLine('</w:document>')

[System.IO.File]::WriteAllText((Join-Path $tempDir "word\document.xml"), $sb.ToString(), [System.Text.Encoding]::UTF8)

# Comprimir a archivo .docx final
if (Test-Path $outputDocx) {
    Remove-Item -Path $outputDocx -Force
}
[System.IO.Compression.ZipFile]::CreateFromDirectory($tempDir, $outputDocx)

# Limpiar directorio temporal
Remove-Item -Path $tempDir -Recurse -Force

$fileInfo = Get-Item $outputDocx
Write-Host "DOCX generado exitosamente: $($fileInfo.FullName) (Tamaño: $($fileInfo.Length) bytes)"
