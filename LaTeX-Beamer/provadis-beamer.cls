\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{provadis-beamer}

\LoadClass[aspectratio=169]{beamer}

\RequirePackage{fontspec}
\usefonttheme{professionalfonts}
\RequirePackage{unicode-math}

\setmainfont[Ligatures=TeX]{Cambria}[
	UprightFont=Cambria.ttc,
	BoldFont=Cambriab.ttf,
	ItalicFont=Cambriai.ttf,
	BoldItalicFont=Cambriaz.ttf
]
\setsansfont[Ligatures=TeX]{Arial}

% erfordert unter macOS die Installation von Consola{,b,i,z}.ttf (unter /Applications/Microsof PowerPoint.app/Contents/Resources/DFonts)
\setmonofont{Consolas}%[
%	Extension=.ttf,
%	UprightFont=Consola,
%	BoldFont=Consolab,
%	ItalicFont=Consolai,
%	BoldItalicFont=Consolaz
%]

% erfordert unter macOS die Installation von Cambria.ttc (unter /Applications/Microsof PowerPoint.app/Contents/Resources/DFonts)
\setmathfont{Cambria Math}
% \smblkcircle ist nicht definiert, wenn unicode-math geladen wird -- warum auch immer.
\providecommand{\smblkcircle}{\textbullet}


\RequirePackage{tikz}% Positionieren von Hintergrundbild und Signet auf der Titelseite
\RequirePackage{adjustbox}% Einfacheres Trimmen des Hintergrundbilds auf der Titelseite
\RequirePackage{etoolbox}% Patchen von Commands sowie Implementierung spezieller frame-Optionen
\RequirePackage{xpatch}% Patchen von Commands
% TODO: etoolbox-Commands nutzen oder andersrum?

\RequirePackage{scrextend}% Setzen der Schriftgröße
\RequirePackage{setspace}% Anpassen des Zeilenabstands


\usetheme{ThinkingIndustryNew}

\let\original@titlepage=\titlepage
\RenewDocumentCommand{\titlepage}{}{%
	\ifbeamer@inframe%
		TOO LATE!!!% TODO
	\else%
		\begingroup%
			\setbeamertemplate{frametitle}{}%
			\begin{frame}[plain,nosignet,nobackground]%
				\original@titlepage%
			\end{frame}%
		\endgroup%
		\beamer@calculateheadfoot% sonst fehlt auf dem folgenden frame die Fußzeile...
	\fi}


