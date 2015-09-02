mmark=mmark
xml2rfc=xml2rfc

all: txt html
txt: DNS3-RR-Protocol.txt
html: DNS3-RR-Protocol.html

DNS3-RR-Protocol.xml: DNS3-RR-Protocol.md
	$(mmark) -page -xml2 DNS3-RR-Protocol.md > DNS3-RR-Protocol.xml

DNS3-RR-Protocol.html: DNS3-RR-Protocol.xml
	$(xml2rfc) --html DNS3-RR-Protocol.xml

DNS3-RR-Protocol.txt: DNS3-RR-Protocol.xml
	$(xml2rfc) --text DNS3-RR-Protocol.xml

clean:
	rm -f DNS3-RR-Protocol.{txt,html,xml}
