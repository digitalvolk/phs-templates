\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{Provadis-Klausur}[2023-09-20, basierend auf Word-Vorlage vom 2022-12-15]

\newif\if@provadis@klausur@loesung\@provadis@klausur@loesungfalse

\RequirePackage{kvoptions}
\SetupKeyvalOptions{
	family=@provadis@klausur,
	prefix=@provadis@klausur@
}

\DeclareVoidOption{loesung}{
	\@provadis@klausur@loesungtrue
}

\DeclareDefaultOption{\ClassWarning{Provadis-Klausur}{Unbekannte Option '\CurrentOption'!}}
\ProcessKeyvalOptions*\relax

\LoadClass[11pt,
	parskip=half-
]{scrartcl}

\RequirePackage[ngerman]{babel}

\RequirePackage[
	left=2cm,
	right=1.25cm,
	top=4cm,
	bottom=1.75cm,
	head=20.4pt% sonst meckert scrlayer-scrpage
]{geometry}
\setlength{\footheight}{20.4pt}% sonst meckert scrlayer-scrpage

\RequirePackage{array}
\RequirePackage{tabularx}
\RequirePackage{graphicx}
\RequirePackage[export]{adjustbox}
\RequirePackage{stackengine}
\RequirePackage{scrlayer-scrpage}
\RequirePackage{multirow}
\RequirePackage{ifthen}
\RequirePackage{totcount}
\RequirePackage{lastpage}
\RequirePackage{pgffor}
\RequirePackage[shortlabels]{enumitem}
\RequirePackage[stamp=false,firstpageonly=true]{draftwatermark}

\RequirePackage{iftex}
\ifTUTeX
	% LuaLaTeX (beorzugt) oder XeLaTeX, allgemein: Unicode-fähige Engine, in der wir auch fontspec laden können.
	\RequirePackage{fontspec}
	% sollte vor Änderungen der Fonts geladen werden, weil es die fontspec-Commands erweitert
	\RequirePackage{unicode-math}
	
	% erst Cambria laden, damit \mathrm darauf abbildet
	% erfordert unter macOS die Installation von Cambria.ttc (unter /Applications/Microsof PowerPoint.app/Contents/Resources/DFonts)
	\setmainfont[Ligatures=TeX]{Cambria}
	\setmathfont{Cambria Math}

	\setromanfont[Ligatures=TeX]{Times New Roman}
	\setsansfont[Ligatures=TeX]{Arial}
	\renewcommand*\familydefault{\sfdefault}
	\setmonofont{Consolas}
\else
	% pdfLaTeX (oder noch schlimmer: LaTeX) (nicht empfohlen!)
	\RequirePackage[T1]{fontenc}
	\RequirePackage[utf8]{inputenc}
	\RequirePackage{helvet}
	% mit pdfLaTeX nutzen wir Times New Roman (bzw. einen Klon davon) für Roman und Mathematiksatz.
	% Letzteres, weil wir keine Möglichkeit haben, auf z.B. Cambria Math zu wechseln.
	\RequirePackage{newtxtext,newtxmath}
	\RequirePackage{courier}
	\renewcommand*\familydefault{\sfdefault}
	% noch eine schöne Warnung ausgeben
	\ClassWarning{Provadis-Klausur}{pdfLaTeX wird nur rudimentär unterstützt; LuaLaTeX (oder zur Not XeLaTeX) liefern bessere Klausuren!}
\fi

\ifLuaTeX
	\RequirePackage{lua-ul}
	% lua-ul hat zwar eine [soul]-Option, die ein soul[utf8]-kompatibles \ul-Makro definiert,
	% aber wir nutzen stattdessen unser eigenes Makro, das eine angepasste Distanz und Dicke der Unterstreichung hat
	% und Words (schlechtes) Verhalten besser imitiert.
	\newunderlinetype\@underline{%
		% Werte empirisch bestimmt
		\leaders\vrule height -.2ex depth .4ex%
	}
	\NewDocumentCommand{\ul}{m}{%
		{\@underline#1}%
	}
\else
	% nicht LuaLaTeX, deshalb müssen wir soulutf8 nutzen, das wir wiederum anpassen
	\RequirePackage{soulutf8}
	\setul{.2ex}{.2ex}% depth, thickness. Werte siehe oben, da müssen sie aber anders spezifiziert werden
\fi

% in Punkteverteilungs-Tabelle genutzt, benötigt stackengine
\newcommand\xrowht[2][0]{\addstackgap[.5\dimexpr#2\relax]{\vphantom{#1}}}

\DeclareNewLayer[
head,
voffset=1cm,
align=t,
contents={%
	\begin{tabularx}{\textwidth}{@{}Xr@{}}
		\hline
		\begin{minipage}{5cm}\raggedright\linespread{1.0}\selectfont
			\,\\
			\,\\
			Provadis Hochschule \\
			Prüfungsamt\\
			\,\\
		\end{minipage} & \includegraphics[valign=m,width=5.49cm,raise=-2ex]{Provadis} \\
		\hline
	\end{tabularx}}
]{@provadis@klausur@header}

\DeclareNewLayer[
	foot,
	align=b,
	voffset=\paperheight-1cm,
	contents={%
		\fontsize{6pt}{6pt}\selectfont\textsuperscript{©} \textbf{Provadis} School of International Management and Technology AG \hfill Seite~\thepage{} von~\pageref{LastPage}}
]{@provadis@klausur@footer}

\AddLayersAtBeginOfPageStyle{scrheadings}{@provadis@klausur@header}
\AddLayersAtBeginOfPageStyle{scrheadings}{@provadis@klausur@footer}
\cfoot{}

% Werden ins aux-File geschrieben und im nächsten Durchlauf genutzt, um die Tabelle auf dem Deckblatt zu füllen
\newtotcounter{@provadis@klausur@anzahlaufgaben}
\newtotcounter{@provadis@klausur@gesamtpunkte}

% Werden von \@provadis@klausur@process@teilaufgaben mit Anzahl und Gesamtpunkten der aktuellen Aufgabe gefüllt
\newcounter{@provadis@klausur@teilaufgabe@anzahl}
\newcounter{@provadis@klausur@teilaufgabe@punkte}

% Wird von \@provadis@klausur@process@teilaufgaben mit Befehlen befüllt,
% die die Teilaufgaben-Punktezeilen erzeugen.
% Danach von \@provadis@klausur@anzahlaufgaben@header konsumiert.
\newcommand\@provadis@klausur@teilaufgabe@zeilen{}

% Teil-Punkte-Spalten in Tabellen werden um diesen Betrag links/rechts eingerückt, damit's schöner aussieht
\def\@provadis@klausur@teilaufgabe@punkte@padding{1.5em}

\NewDocumentCommand{\@provadis@klausur@process@teilaufgaben}{m}{%
	\setcounter{@provadis@klausur@teilaufgabe@anzahl}{0}%
	\setcounter{@provadis@klausur@teilaufgabe@punkte}{0}%
	\gdef\@provadis@klausur@teilaufgabe@zeilen{}%
	\foreach \punkte in {#1} {%
		\stepcounter{@provadis@klausur@teilaufgabe@anzahl}%
		\addtocounter{@provadis@klausur@teilaufgabe@punkte}{\punkte}%
		% Zeile für Teilaufgabe anhängen
		\g@addto@macro\@provadis@klausur@teilaufgabe@zeilen{\hspace{\@provadis@klausur@teilaufgabe@punkte@padding}}%
		\edef\@tmp{\alph{@provadis@klausur@teilaufgabe@anzahl})&&/&\punkte}%
		\expandafter\g@addto@macro\expandafter\@provadis@klausur@teilaufgabe@zeilen\expandafter{\@tmp\hspace*{\@provadis@klausur@teilaufgabe@punkte@padding}\tabularnewline\hline}%
	}%
	% Zusammenfassungs-Zeile anhängen
	\ifthenelse{\value{@provadis@klausur@teilaufgabe@anzahl}=1}{
		% wenn nur eine Teilaufgabe existiert, nur die Zusammenfassungs-Zeile erzeugen.
		% Also: Bisherige Zeilen leeren
		\gdef\@provadis@klausur@teilaufgabe@zeilen{}%
	}{}%
	\g@addto@macro\@provadis@klausur@teilaufgabe@zeilen{&&\textbf{/}&\begingroup\bfseries}%
	\edef\@tmp{\arabic{@provadis@klausur@teilaufgabe@punkte}}%
	\expandafter\g@addto@macro\expandafter\@provadis@klausur@teilaufgabe@zeilen\expandafter{\@tmp\hspace*{\@provadis@klausur@teilaufgabe@punkte@padding}\endgroup}%
}

\NewDocumentCommand{\@provadis@klausur@anzahlaufgaben@header}{}{%
	\begin{tabularx}{\textwidth}{@{}|@{}>{\centering\arraybackslash}p{5cm}@{}|@{}>{\centering\arraybackslash}p{7.8cm}@{}|@{}X@{}|}
		\hline
		Aufgabe~\arabic{@provadis@klausur@anzahlaufgaben} & \parbox{\dimexpr\linewidth-2em\relax}{\centering \strut Abschlussklausur zur Vorlesung: \\
			\textbf{\Veranstaltung} \\
			Studiengang: \Studiengang \\
			Semester: \Semester\strut}
		& {\begin{tabularx}{\linewidth}{cXc@{~}r}
				\@provadis@klausur@teilaufgabe@zeilen
		\end{tabularx}}\\\hline
	\end{tabularx}
}

\NewDocumentCommand{\Aufgabe}{O{}m}{%
	\stepcounter{@provadis@klausur@anzahlaufgaben}%
	\@provadis@klausur@process@teilaufgaben{#2}%
	\addtocounter{@provadis@klausur@gesamtpunkte}{\value{@provadis@klausur@teilaufgabe@punkte}}%
	\edef\counter@name{@provadis@aufgabe@\arabic{@provadis@klausur@anzahlaufgaben}@punkte}
	\expandafter\newtotcounter\expandafter{\counter@name}%
	\expandafter\setcounter\expandafter{\counter@name}{\value{@provadis@klausur@teilaufgabe@punkte}}%
	%
	\clearpage%
	\@provadis@klausur@anzahlaufgaben@header\\[0.75\baselineskip]%
	\textbf{Aufgabe \arabic{@provadis@klausur@anzahlaufgaben}: #1}\par%
}

\newcommand\@provadis@klausur@punkteverteilung@zeile@eins{}
\newcommand\@provadis@klausur@punkteverteilung@zeile@zwei{}
\newcommand\@provadis@klausur@punkteverteilung@zeile@drei{}
\newcounter{@provadis@klausur@punkteverteilung@aktuelleAufgabe}
\NewDocumentCommand{\@provadis@klausur@process@punkteverteilung}{}{%
	\gdef\@provadis@klausur@punkteverteilung@zeile@eins{}%
	\gdef\@provadis@klausur@punkteverteilung@zeile@zwei{}%
	\gdef\@provadis@klausur@punkteverteilung@zeile@drei{}%
	% Versuch zum Umbau auf \foreach (pgffor) hat nicht geklappt, daher primitiver...
	\setcounter{@provadis@klausur@punkteverteilung@aktuelleAufgabe}{1}%
	\loop\unless\ifnum\value{@provadis@klausur@punkteverteilung@aktuelleAufgabe}>\numexpr\totvalue{@provadis@klausur@anzahlaufgaben}\relax%
		\edef\aktuelleAufgabe{\arabic{@provadis@klausur@punkteverteilung@aktuelleAufgabe}}%
		\edef\counter@name{@provadis@aufgabe@\aktuelleAufgabe @punkte}%
		\edef\aktuellePunkte{\the\numexpr\expandafter\totvalue\expandafter{\counter@name}\relax}%
		%
		% Zeile 1: Aufgabennummer in fett
		\g@addto@macro\@provadis@klausur@punkteverteilung@zeile@eins{\begingroup\bfseries}%
		\expandafter\g@addto@macro\expandafter\@provadis@klausur@punkteverteilung@zeile@eins\expandafter{\aktuelleAufgabe\endgroup&}%
		% Zeile 2: Erreichbare Punktzahl
		\expandafter\g@addto@macro\expandafter\@provadis@klausur@punkteverteilung@zeile@zwei\expandafter{\aktuellePunkte&}%
		% Zeile 3: Leer
		\g@addto@macro\@provadis@klausur@punkteverteilung@zeile@drei{&}%
		%
		\stepcounter{@provadis@klausur@punkteverteilung@aktuelleAufgabe}%
	\repeat%
}

\NewDocumentCommand{\@provadis@klausur@check@punkteverteilung}{}{%
	% Sicherstellen, dass die Anzahl der Aufgaben im Vergleich zum letzten Durchlauf gleich geblieben ist.
	\ifthenelse{\value{@provadis@klausur@anzahlaufgaben}=\totvalue{@provadis@klausur@anzahlaufgaben}}{%
		% Anzahl der Aufgaben ist identisch.
		% Zusätzlich sicherstellen, dass die Anzahl der Punkte pro Aufgabe auch gleich geblieben ist.
		%
		% Siehe oben: Versuch zum Umbau auf \foreach (pgffor) hat nicht geklappt, daher primitiver...
		\setcounter{@provadis@klausur@punkteverteilung@aktuelleAufgabe}{1}%
		\loop\unless\ifnum\value{@provadis@klausur@punkteverteilung@aktuelleAufgabe}>\numexpr\totvalue{@provadis@klausur@anzahlaufgaben}\relax%
			\edef\aktuelleAufgabe{\arabic{@provadis@klausur@punkteverteilung@aktuelleAufgabe}}%
			\edef\counter@name{@provadis@aufgabe@\aktuelleAufgabe @punkte}%
			\edef\aktuellePunkte{\the\numexpr\expandafter\value\expandafter{\counter@name}\relax}%
			\edef\vorherigePunkte{\the\numexpr\expandafter\totvalue\expandafter{\counter@name}\relax}%
			\ifx\aktuellePunkte\vorherigePunkte\else%
				\PackageError{Provadis-Klausur}{Punkte für Aufgabe \aktuelleAufgabe\space haben sich geändert, Neukompilierung nötig!}%
			\fi%
			\stepcounter{@provadis@klausur@punkteverteilung@aktuelleAufgabe}%
		\repeat%
	}{%
		\PackageError{Provadis-Klausur}{Anzahl der Aufgaben hat sich geändert, Neukompilierung nötig!}
	}%
}

\newcounter{@provadis@klausur@punkteverteilung@zusatzspalten}
\NewDocumentCommand{\provadis@klausur@process@zusatzspalten}{m}{%
	\setcounter{@provadis@klausur@punkteverteilung@zusatzspalten}{0}%
	\foreach \header/\punkte in #1 {%
		\stepcounter{@provadis@klausur@punkteverteilung@zusatzspalten}%
		\g@addto@macro\@provadis@klausur@punkteverteilung@zeile@eins{\begingroup\bfseries}%
		\expandafter\g@addto@macro\expandafter\@provadis@klausur@punkteverteilung@zeile@eins\expandafter{\header\endgroup&}%
		\expandafter\g@addto@macro\expandafter\@provadis@klausur@punkteverteilung@zeile@zwei\expandafter{\punkte&}%
		\g@addto@macro\@provadis@klausur@punkteverteilung@zeile@drei{&}%
	}%
}

\NewDocumentCommand{\@provadis@klausur@titelseite}{}{%
	\raggedright
	{\renewcommand{\arraystretch}{1.4}\begin{tabular}{@{}>{\bfseries}l>{\bfseries}l}
			Vorlesung: & \Veranstaltung \\
			Semester: & \Semester \\
			\ifx\Studiengruppe\undefined%
				Studiengang:
			\else
				Studiengang / -gruppe:
			\fi
			&% Conditionals können sich nicht über Alignment-Cells hinweg erstrecken...
			\ifx\Studiengruppe\undefined%
				\Studiengang
			\else%
				\Studiengang\space/ \Studiengruppe
			\fi\\
			Dozent(en): & \Dozent \\
			Datum: & \Datum \\
			Bearbeitungszeit in Minuten: & \DauerMinuten \\
			Marikelnummer: & \\
			Zugelassene Hilfsmittel: & \ifx\Hilfsmittel\undefined Keine\else\Hilfsmittel\fi
	\end{tabular}}
	
	\vspace{1\baselineskip}
	\textbf{Wichtige Hinweise:}
	\begin{itemize}
		\item Sollten Sie sich nicht gesund fühlen, so melden Sie sich \textbf{\ul{vor}} Beginn der Bearbeitungszeit bei der Aufsicht; ein Abbruch nach Beginn führt zur Bewertung der bis dahin vorliegenden Ergebnisse!
		\item Es sind nur die oben \textbf{\ul{angegebenen Hilfsmittel zugelassen}}.
		% innerhalb von \ul müssen direkt die Unicode-Quotes genutzt werden, sonst werden die irgendwie nicht expandiert (zumindest mit lua-ul; mit soulutf8 ist's wahrscheinlich sonst sogar ein Fehler, wenn die Shorthands nicht definiert wurden)
		\item Im Falle von Täuschungsversuchen wird die Klausur als \textbf{\ul{„nicht bestanden“}} bewertet.
		\item Überprüfen Sie die Ihnen vorliegende \textbf{\ul{Klausur auf Vollständigkeit}}.
		\item Bitte schreiben Sie \textbf{\ul{leserlich}} und verwenden Sie nur \textbf{\ul{dokumentenechte Stifte}}.
		\item Lassen Sie einen angemessenen \textbf{\ul{Korrekturrand}} auf beiden Seiten\newline
		(ca. 20 - 30\% der Seitenbreite).
		\item Versehen Sie sowohl Aufgabenblatt als auch jedes Blatt des Klausurpapiers mit Ihrer \textbf{\ul{Matrikelnummer}}. Sollten Sie weiteres Klausurpapier benötigen, wenden Sie sich an die Klausuraufsicht.
		\item Kennzeichnen Sie das Konzeptpapier mit „Konzept“. Ausführungen auf dem Konzeptpapier werden \textbf{\ul{nicht}} in die Bewertung mit einbezogen.
		\item Tragen Sie in eigenem Interesse Sorge, dass nach Klausurschluss \textbf{\ul{alle ausgeteilten Unterlagen}} einschließlich der Aufgabenstellung an die Aufsicht \textbf{\ul{zurückgegeben}} werden.
	\end{itemize}
	
	{
		\fontsize{14pt}{14pt}\selectfont
		\null\hfill\bfseries Wir wünschen Ihnen viel Erfolg.\hfill\null
	}
	
	
	\@provadis@klausur@process@punkteverteilung
	\ifx\PunkteZusatzspalten\undefined\else
		\provadis@klausur@process@zusatzspalten{\PunkteZusatzspalten}
	\fi
	\textbf{Punkteverteilung}\\[-0.5ex]
	\null\hfill{\begin{tabular}{@{}|@{}c@{}|*{\totvalue{@provadis@klausur@anzahlaufgaben}}{>{\centering\arraybackslash}p{1cm}|}*{\value{@provadis@klausur@punkteverteilung@zusatzspalten}}{c|}@{}c@{}|@{}}
			\hline\xrowht{1.09cm}
			\textbf{Aufgabe} &%
			\@provadis@klausur@punkteverteilung@zeile@eins%
			\begin{minipage}{2.39cm}\centering\bfseries
				Summe /\\
				Note
			\end{minipage} \\
			\hline\xrowht{1.09cm}
			\begin{minipage}{2.4cm}\centering
				Maximale\\
				Punktzahl
			\end{minipage} &%
			\@provadis@klausur@punkteverteilung@zeile@zwei%
			\textbf{\total{@provadis@klausur@gesamtpunkte}} \\
			\hline\xrowht{1.09cm}
			\begin{minipage}{2.4cm}\centering
				Erreichte\\
				Punktzahl
			\end{minipage} &%
			\@provadis@klausur@punkteverteilung@zeile@drei%
			\begin{minipage}{1cm}\centering
				\textbf{\fontsize{18pt}{18pt}\selectfont/}
			\end{minipage} \\
			\hline
	\end{tabular}}\hfill\null
	
	\ifx\NachPunkteverteilung\undefined\else
		\NachPunkteverteilung
	\fi
	
	\vspace{1\baselineskip}
	Kürzel / Abzeichnung durch den Dozenten:
	
	\clearpage
	\linespread{1.5}\selectfont
}

% Standard-Enumerate-Settings überschreiben, sodass wir standardmäßig nicht einrücken und a), b), c) nummerieren;
\setlist[enumerate,1]{label=\alph*),leftmargin=*}
% auf der nächsten Ebene dann römisch (da wäre a), b), c) Standard)
\setlist[enumerate,2]{label=\roman*),leftmargin=*}

\ifx\newfontfamily\undefined\else
	% fontspec geladen, also LuaTeX oder XeTeX.
	% Andernfalls (pdfTeX) überspringen wir die Verschönerung der Aufzählungszeichen einfach.
	%
	% im Original sind die Aufzählungszeichen in Symbol 12pt gesetzt (\textbullet ist in dieser Schriftart etwas größer als Arial)
	\newfontfamily{\symbolfamily}{Symbol}
	\renewcommand\labelitemi{\raisebox{-0.2ex}{\symbolfamily\fontsize{12pt}{12pt}\selectfont\textbullet}}
\fi
% Werte empirisch bestimmt, damit sie halbwegs mit Word übereinstimmen
\setlist[itemize,1]{leftmargin=2.5em,labelsep=0.75em}

% Lösungs-Befehle
\if@provadis@klausur@loesung
	\AtBeginDocument{% Vom Benutzer in der Präambel gesetzte Werte überschreiben; Lösungs-Hinweis hat Vorrang.
		\SetWatermarkScale{0.75}%
		\SetWatermarkText{\textbf{LÖSUNG}}%
		\DraftwatermarkOptions{stamp=true}%
	}
	

	% Inhalt des Environments wird nur bei _deaktivierter_ Lösung angezeigt:
	\NewDocumentEnvironment{nurAufgabe}{+b}{}{}
	\NewDocumentEnvironment{nurLoesung}{}{}{}
	\RequirePackage[many]{tcolorbox}
	\newtcolorbox{loesung}{
		breakable,
		boxrule=1pt,
		enhanced,
		interior style={white},
		fonttitle=\bfseries,
		colbacktitle=white,
		coltitle=black,
		title={Lösung}}
	
	% inline-Lösung
	\NewDocumentCommand{\loes}{s+m}{\IfBooleanTF{#1}{#2}{\ifmmode#2\else\textbf{#2}\fi}}
	\NewDocumentCommand{\platz}{m}{}
\else
	% Keine Lösungen
	\NewDocumentEnvironment{nurAufgabe}{}{}{}
	\NewDocumentEnvironment{loesung}{+b}{}{}
	\NewDocumentEnvironment{nurLoesung}{+b}{}{}
	% inline-Lösung
	\NewDocumentCommand{\loes}{s+m}{}
	\NewDocumentCommand{\platz}{m}{\vspace*{#1}}
\fi


\AtBeginDocument{\@provadis@klausur@titelseite}
\AtEndDocument{\@provadis@klausur@check@punkteverteilung}
