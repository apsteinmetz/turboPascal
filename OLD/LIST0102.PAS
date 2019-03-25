program list0102;
uses
  GrafLib0;

VAR
pt1,pt2,pt3,pt4,center : pixelvector;
polygon : pixelarray;

BEGIN
  PrepIt;
  RGBLog(8,0.5,0.5,0.5);
  SetCol(8);

  polygon[1].x := 0;   polygon[1].y := 0;
  polygon[2].x := nxpix-1;   polygon[2].y := 0;
  polygon[3].x := 0;   polygon[3].y := nypix-1;
  polypix(3,polygon);

  pt1.x := round(nxpix*0.25);
  pt1.y := round(nypix*0.25);
  pt3.x := round(nxpix*0.75);
  pt3.y := round(nypix*0.75);
  pt2.x := pt1.x;
  pt2.y := pt3.y;
  pt4.x := pt3.x;
  pt4.y := pt1.y;

  setcol(7);
  movepix(pt1);
  linepix(pt2);  linepix(pt3);
  linepix(pt4);  linepix(pt1);

  center.x := round(nxpix*0.5);
  center.y := round(nypix*0.5);
  setpix(center);
  finish;

END.