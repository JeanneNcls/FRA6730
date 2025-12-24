<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">
    <xsl:output method="html" encoding="UTF-8" indent="yes" omit-xml-declaration="yes"/>

    <xsl:key name="places" match="tei:place" use="@xml:id"/>
    
    <xsl:template match="/">
        <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>
        <html lang="fr">
            <head>
                <meta charset="utf-8"/>
                <link rel="stylesheet" type="text/css" href="style.css"/>
                <link rel="stylesheet" type="text/css" href="index.css"/>
                <script src="menu_hamburger.js"/>
                <script src="liste_deroulante.js"/>
                <script src="ressources_dynamiques.js"/>

                <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>
                <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"/>

                <meta name="viewport" content="width=device-width, initial-scale=1"/>
                <link rel="stylesheet"
                    href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css"/>

                <title>Vingt mille lieues sous les mers</title>
              

            </head>



            <body>
                <button onclick="topFunction()" id="bouton" title="revenir_en_haut">⬆</button>
                <script src="bouton.js"></script>
                <div class="banniere" alt="banniere">
                    <div class="sous-titre">
                        <p class="vml">Vingt mille lieues sous les mers</p>
                        <p>Jules Verne</p>
                    </div>
                </div>
                <nav class="menu-container">
                    <ul class="menu">
                        <li><a href="index.html" class="page_active">Cartographie</a>
                        </li>
                        
                        <li>Personnages
                            <ul class="sous">
                                <li class="deroulant"><a href="aronnax.html">Pierre Aronnax</a></li>
                                <li class="deroulant"><a href="conseil.html">Conseil</a></li>
                                    <li class="deroulant"><a href="nedland.html">Ned Land</a></li>
                                        <li class="deroulant"><a href="capitainenemo.html">Le Capitaine Nemo</a>
                                        </li>
                            </ul>
                        </li>
                        <li><a href="themes.html">Thèmes</a>
                            <ul class="sous">
                                <li class="deroulant"><a href="phosphorescence.html">Phosphorescence</a></li>
                                <li class="deroulant"><a href="navigation.html">Navigation</a></li>
                                    <li class="deroulant"><a href="sousmarin.html">Sous-marin</a></li>
                                        <li class="deroulant"><a href="classification.html">Classification</a>
                                        </li>
                            </ul>
                        </li>
                        <li><a href="galerie.html">Galerie</a></li>
                        <li><a href="apropos.html">À propos</a>
                        </li>
                    </ul>
                </nav>
                <div class="carte">
                
                <div id="sections" style="display:none">
                    <xsl:for-each select="//tei:div2[@type = 'section']">
                        <div class="section" id="sec-{position()}">
                            <xsl:apply-templates select=".//tei:p"/>
                        </div>
                    </xsl:for-each>
                </div>
                    <script>
                        /* =========================
                        1. Création de la carte
                        ========================= */
                        var map = L.map('map', {
                        worldCopyJump: true
                        }).setView([20, 0], 3);
                        
                        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                        attribution: 'OpenStreetMap'
                        }).addTo(map);
                        
                        /* =========================
                        2. Lecteur plein écran
                        ========================= */
                        var reader = document.createElement('div');
                        reader.id = 'reader';
                        reader.style.display = 'none';
                        reader.style.position = 'fixed';
                        reader.style.top = 0;
                        reader.style.left = 0;
                        reader.style.width = '100vw';
                        reader.style.height = '100vh';
                        reader.style.backgroundColor = 'white';
                        reader.style.zIndex = 2000;
                        reader.style.overflow = 'auto';
                        reader.style.padding = '2rem';
                        reader.style.boxSizing = 'border-box';
                        reader.innerHTML =
                        '<button id="closeReader" style="position:absolute;top:1rem;right:1rem;z-index:3000;">Fermer</button>' +
                        '<div id="readerContent"></div>';
                        document.body.appendChild(reader);
                        
                        document.getElementById('closeReader').onclick = function () {
                        reader.style.display = 'none';
                        };
                        
                        /* =========================
                        3. Collecte des points
                        ========================= */
                        var pathCoords = [];
                        var sections = [];
                        
                        <xsl:for-each select="//tei:div2[@type = 'section']">
                            <xsl:variable name="placeId" select="substring-after(@corresp, '#')"/>
                            <xsl:variable name="geo" select="normalize-space(key('places', $placeId)/tei:location/tei:geo)"/>
                            
                            <xsl:if test="$geo">
                                pathCoords.push([
                                <xsl:value-of select="tokenize($geo, '\s+')[1]"/>,
                                <xsl:value-of select="tokenize($geo, '\s+')[2]"/>
                                ]);
                                
                                sections.push("sec-<xsl:value-of select='position()'/>");
                            </xsl:if>
                        </xsl:for-each>
                        
                        /* =========================
                        4. Normalisation antiméridien
                        ========================= */
                        function unwrapPath(coords) {
                        var result = [];
                        var prevLng = null;
                        
                        coords.forEach(function (pt) {
                        var lat = pt[0];
                        var lng = pt[1];
                        
                        if (prevLng !== null) {
                        while (lng - prevLng > 180) lng -= 360;
                        while (lng - prevLng &lt; -180) lng += 360;
                        }
                        
                        result.push([lat, lng]);
                        prevLng = lng;
                        });
                        
                        return result;
                        }
                        
                        pathCoords = unwrapPath(pathCoords);
                        
                        /* =========================
                        5. Polyline fluide
                        ========================= */
                        var polyline = L.polyline(pathCoords, {
                        color: 'blue',
                        noClip: true
                        }).addTo(map);
                        
                        pathCoords.forEach(function (coords, i) {
                        var marker = L.marker(coords).addTo(map);
                        
                        marker.on('click', function () {
                        document.getElementById('readerContent').innerHTML =
                        document.getElementById(sections[i]).innerHTML;
                        reader.style.display = 'block';
                        });
                        });
                        
                        map.fitBounds(polyline.getBounds());
                    </script>
                    
                </div>
            </body>
        </html>

    </xsl:template>
    <xsl:template match="tei:p">
        <p>
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <xsl:template match="tei:emph">
        <em>
            <xsl:apply-templates/>
        </em>
    </xsl:template>

    <xsl:template match="tei:persName">
        <span class="person">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="tei:date">
        <time>
            <xsl:apply-templates/>
        </time>
    </xsl:template>

    <xsl:template match="tei:desc">
        <span class="desc">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
</xsl:stylesheet>
