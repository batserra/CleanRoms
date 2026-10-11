import json, sys, re
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import (BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer, Table,
                                TableStyle, PageBreak, KeepTogether, CondPageBreak, NextPageTemplate)
from reportlab.lib.enums import TA_LEFT
from xml.sax.saxutils import escape

NAVY=colors.Color(0.1,0.23,0.36)
HEAD=colors.Color(0.121569,0.305882,0.47451)
ZEBRA=colors.Color(0.933333,0.952941,0.972549)
GRID=colors.Color(0.788235,0.831373,0.870588)
GRAY=colors.Color(0.33,0.33,0.33)

S=dict(
 title=ParagraphStyle('title',fontName='Helvetica-Bold',fontSize=28,leading=34,textColor=NAVY,spaceAfter=4),
 subtitle=ParagraphStyle('subtitle',fontName='Helvetica',fontSize=14,leading=18,textColor=colors.Color(0.4,0.4,0.4),spaceAfter=18),
 para=ParagraphStyle('para',fontName='Helvetica',fontSize=10,leading=14,spaceAfter=8),
 toc=ParagraphStyle('toc',fontName='Helvetica',fontSize=10.5,leading=13,spaceAfter=5),
 h1=ParagraphStyle('h1',fontName='Helvetica-Bold',fontSize=16,leading=20,textColor=NAVY,spaceBefore=18,spaceAfter=9,keepWithNext=1),
 h2=ParagraphStyle('h2',fontName='Helvetica-Bold',fontSize=10,leading=13,spaceBefore=8,spaceAfter=8,keepWithNext=1),
 note=ParagraphStyle('note',fontName='Helvetica-Oblique',fontSize=9,leading=13,textColor=GRAY,leftIndent=14,spaceAfter=8),
 code=ParagraphStyle('code',fontName='Courier',fontSize=9,leading=13,textColor=colors.Color(0.2,0.2,0.2),leftIndent=14,spaceAfter=0),
 cell=ParagraphStyle('cell',fontName='Helvetica',fontSize=9.5,leading=12),
 cellb=ParagraphStyle('cellb',fontName='Helvetica-Bold',fontSize=9.5,leading=12),
 cellh=ParagraphStyle('cellh',fontName='Helvetica-Bold',fontSize=9.5,leading=12,textColor=colors.white),
)

def markup(runs):
    out=[]
    for k,t in runs:
        t=escape(t)
        if k=='br': out.append('<br/>'); continue
        if k=='b': out.append('<b>%s</b>'%t)
        elif k=='i': out.append('<i>%s</i>'%t)
        elif k=='code': out.append('<font name="Courier">%s</font>'%t)
        elif k=='sym': out.append('<font name="Symbol">%s</font>'%t)
        elif k=='zapf': out.append('<font name="ZapfDingbats">%s</font>'%t)
        else: out.append(t)
    return ''.join(out)

def make_table(b):
    cols=b['cols']
    widths=[cols[i+1]-cols[i] for i in range(len(cols)-1)]
    scale=489.6/sum(widths)
    widths=[w*scale for w in widths]
    rows=b['rows']; n=len(widths)
    data=[]
    for ri,r in enumerate(rows):
        r=list(r)+['']*(n-len(r))
        cells=[]
        for ci,c in enumerate(r[:n]):
            st=S['cellh'] if ri==0 else (S['cellb'] if ci==0 else S['cell'])
            cells.append(Paragraph(escape(c),st))
        data.append(cells)
    t=Table(data,colWidths=widths,repeatRows=1)
    ts=[('BACKGROUND',(0,0),(-1,0),HEAD),
        ('GRID',(0,0),(-1,-1),0.6,GRID),
        ('VALIGN',(0,0),(-1,-1),'TOP'),
        ('TOPPADDING',(0,0),(-1,-1),5.2),('BOTTOMPADDING',(0,0),(-1,-1),5.2),
        ('LEFTPADDING',(0,0),(-1,-1),6),('RIGHTPADDING',(0,0),(-1,-1),6)]
    for i in range(1,len(rows)):
        ts.append(('BACKGROUND',(0,i),(-1,i),ZEBRA if i%2==1 else colors.white))
    t.setStyle(TableStyle(ts))
    return t

def story_from(blocks):
    story=[]
    first=True
    for b in blocks:
        ty=b['type']
        if ty=='table':
            story.append(make_table(b)); story.append(Spacer(1,10)); continue
        if ty=='code':
            lines=[Paragraph(escape(ln).replace(' ','&nbsp;') or '&nbsp;',S['code']) for ln in b['lines']]
            story.append(KeepTogether(lines+[Spacer(1,8)])); continue
        if ty=='pagebreak':
            story.append(PageBreak()); continue
        st=S[ty]
        if ty=='title': story.append(Spacer(1,120))
        story.append(Paragraph(markup(b['runs']),st))
    return story

def build(blocks,out,footer,title):
    def on_page(c,doc):
        if doc.page==1: return
        c.saveState(); c.setFont('Helvetica',8); c.setFillColor(colors.Color(0.6,0.6,0.6))
        c.drawString(61.2,792-746-6.2,str(doc.page))
        c.drawCentredString(306,792-746-6.2,footer)
        c.restoreState()
    doc=BaseDocTemplate(out,pagesize=letter,title=title,author='(anonymous)',
                        leftMargin=61.2,rightMargin=61.2,topMargin=64.8,bottomMargin=57.6)
    frame=Frame(61.2,57.6,489.6,792-64.8-57.6,leftPadding=6,rightPadding=6,topPadding=6,bottomPadding=6,id='f')
    doc.addPageTemplates([PageTemplate(id='p',frames=[frame],onPage=on_page)])
    doc.build(story_from(blocks))

def read_version():
    import os
    p=os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','VERSION')
    try: return open(p,encoding='utf-8').read().strip().splitlines()[0]
    except Exception: return 'dev'

if __name__=='__main__':
    # Uso: build.py manual.json salida.pdf "pie de pagina" "titulo"
    # En el pie y el titulo, {version} se sustituye por el contenido de ..\VERSION
    v=read_version()
    blocks=json.load(open(sys.argv[1],encoding='utf-8'))
    build(blocks,sys.argv[2],sys.argv[3].replace('{version}',v),sys.argv[4].replace('{version}',v))
