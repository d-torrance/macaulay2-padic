FILENAME = macaulay2-padic

all:

arxiv: tikz-uml.sty llncs.cls
	sed -i 's/ge{mi/ge[finalizecache]{mi/' $(FILENAME).tex
	pdflatex -shell-escape $(FILENAME)
	bibtex $(FILENAME)
	pdflatex -shell-escape $(FILENAME)
	pdflatex -shell-escape $(FILENAME)
	sed -i 's/finalizecache/frozencache/' $(FILENAME).tex
	pdflatex $(FILENAME)
	rm -rf tar && mkdir tar
	cp -r _minted-$(FILENAME) tar
	cp $(FILENAME).tex tar
	cp $(FILENAME).bbl tar
	cp /usr/share/texlive/texmf-dist/tex/latex/minted/minted1.sty tar
	cp /usr/share/texlive/texmf-dist/tex/latex/minted/minted.sty tar
	cp $^ tar
	cd tar && tar -czvf ../$(FILENAME).tar.gz .
	sed -i 's/\[frozencache\]//' $(FILENAME).tex
