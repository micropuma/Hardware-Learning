# How to user overleaf to make a ppt
## A general tutorial    
below is the template for overleaf beamer.
```Latex
\documentclass[14pt, aspectratio=169, handout]{beamer}
\usetheme{Copenhagen}
%\usecolortheme{beaver}

%\usepackage{pgfpages}
%\pgfpagesuselayout{4 on 1}[a4paper,border shrink=5mm]

\setbeamertemplate{navigation symbols}{}
\setbeamercovered{transparent}
\setbeamertemplate{headline}{}

\title{Beam Pracitce}
\author{Dou Leon}
\date{November 2024}

\begin{document}

\maketitle

\begin{frame}{Title Page}
\tableofcontents
\end{frame}

\section{1}
\begin{frame}{Overleaf}

\begin{itemize}
    \item<1-> Collabo 
    \item<2-> EJEJEJJ
    \item<3-> djdjjd
\end{itemize}

\only<2>{click the clock button}\only<3>{click the review button}

I can do an \alert<1>{Alert}. I can also to \textbf<2>{bold face}.

\end{frame}

\section{2}
\begin{frame}{Special Environments}

\begin{block}{Remark}
some text
\end{block}

\begin{example}
This is an example
\end{example}

\begin{theorem}[Pythagoras]
    $a^2+b^2=c^2$
\end{theorem}

\begin{proof}<2>
Left to the interested reader.
\end{proof}

\end{frame}

\section{3}
\begin{frame}{Two column frame}
    \begin{columns}
        \column{0.5\textwidth}Thisd
        \column{0.5\textwidth}Thisdjjdjdd
    \end{columns}
\end{frame}

\begin{frame}{Frame Title}
    Extra frame1
\end{frame}

\subsection{Dummy subsection}

\begin{frame}{Frame Title}
    Extra frame2
\end{frame}

\end{document}
```
refer to [overleaf beamer doc](https://www.overleaf.com/learn/latex/Beamer#Reference_guide) for further knowledge.


## References
1. [Overleaf-ppt talk](https://www.youtube.com/watch?v=rx7wwtmFlD8&t=18s)