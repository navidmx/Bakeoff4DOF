import java.util.ArrayList;
import java.util.Collections;

//these are variables you should probably leave alone
int index = 0; //starts at zero-ith trial
float border = 0; //some padding from the sides of window
int trialCount = 12; //this will be set higher for the bakeoff
int trialIndex = 0; //what trial are we on
int errorCount = 0;  //used to keep track of errors
float errorPenalty = 0.5f; //for every error, add this value to mean time
int startTime = 0; // time starts when the first click is captured
int finishTime = 0; //records the time of the final click
boolean userDone = false; //is the user done

boolean printMessage = false;

final int screenPPI = 72; //what is the DPI of the screen you are using
//you can test this by drawing a 72x72 pixel rectangle in code, and then confirming with a ruler it is 1x1 inch. 

private class SubmitButton {
  float buttonWidth = inchToPix(1f);
  float buttonHeight = inchToPix(.5f);
  float x;
  float y;
  
  public SubmitButton() {
    x = width/2;
    y = height - buttonHeight/2;
  }
  
  public void drawButton() {
    noStroke();
    
    fill(0,255,0);
    rect(x, y, buttonWidth, buttonHeight);
    
    fill(0,0,0);
    text("Submit", x, y);
  }
  
  public boolean underMouse() {
    return (x - buttonWidth/2 <= mouseX && mouseX <= x + buttonWidth/2)
          && (y - buttonHeight/2 <= mouseY && mouseY <= y + buttonWidth/2);
  }
}

SubmitButton submitButton;

private class Anchor {
  int id = -1;
  float x = 0;
  float y = 0;
  float z = 10f;
  
  // These are the absolute coords, not relative to the logo center
  float absX = 0;
  float absY = 0;
  
  public Anchor(int id) {
    this.id = id;
  }
  
  public int getId() {
    return this.id;
  }
  
  public void updateAll(float x, float y, float z) {
    this.x = x;
    this.y = y;
    this.z = z;
  }
  
  public void updateAbsPosition(float x, float y) {
    this.absX = x;
    this.absY = y;
  }
  
  public boolean underMouse() {
    return dist(this.x, this.y, adjMouseX(), adjMouseY()) < this.z;
  }
  
  // Assume coordinates have been translated by caller
  public void drawAnchor() {
    noStroke();
    fill(192, 192, 60, 100);
    circle(this.x, this.y, this.z);
  }
}

private class Logo {
  float x = 0;
  float y = 0;
  float z = 50f;
  float rotation = 0;
  
  Anchor[] cornerAnchors = new Anchor[4];
  int prevActiveCornerAnchorId = -1;
  int currActiveCornerAnchorId = -1;

  boolean grabbingCorner = false;
  
  public Logo() {
    for (int i = 0; i < 4; i++) {
      this.cornerAnchors[i] = new Anchor(i);
    }
    
    float anchorShift = this.z / 2f;
    this.cornerAnchors[0].updateAbsPosition(width/2 - anchorShift, height/2 - anchorShift);
    this.cornerAnchors[1].updateAbsPosition(width/2 + anchorShift, height/2 - anchorShift);
    this.cornerAnchors[2].updateAbsPosition(width/2 + anchorShift, height/2 + anchorShift);
    this.cornerAnchors[3].updateAbsPosition(width/2 - anchorShift, height/2 + anchorShift);
    
    this.updateAnchorPositions();
  }
  
  public void updateAnchorPositions() {
    float anchorSize = this.z / 4f;
    float anchorShift = this.z / 2f;
    
    // Anchor coordinates should be relative to Logo's center
    
    this.cornerAnchors[0].updateAll(-anchorShift, -anchorShift, anchorSize);
    this.cornerAnchors[1].updateAll(anchorShift, -anchorShift, anchorSize);
    this.cornerAnchors[2].updateAll(anchorShift, anchorShift, anchorSize);
    this.cornerAnchors[3].updateAll(-anchorShift, anchorShift, anchorSize);
  }
  
  public void drawLogo() {
    pushMatrix();
    translate(width/2 + this.x, height/2 + this.y); // center the screen coords on the logo coords 
    rotate(radians(this.rotation));
    noStroke();
    fill(60, 60, 192, 192);
    rect(0, 0, this.z, this.z);
    
    for (int i = 0; i < 4; i++) {
      this.cornerAnchors[i].drawAnchor();
    }
    
    popMatrix();
    
    if (this.prevActiveCornerAnchorId != -1) {
      noStroke();
      Anchor temp = this.cornerAnchors[this.prevActiveCornerAnchorId];
      fill(255, 0, 0);
      circle(temp.absX, temp.absY, 10f);
      temp = this.cornerAnchors[this.currActiveCornerAnchorId];
      fill(0, 255, 0);
      circle(temp.absX, temp.absY, 10f);
    }
  }
  
  public boolean mouseOverCorner() {
    boolean b = false;
    for (int i = 0; i < 4; i++) {
      b = b || this.cornerAnchors[i].underMouse();
    }
    return b;
  }
  
  public void updateActiveCornerAnchor() {
    // At this point, curr- and prev-ActiveCornerAnchors have correct absX/absY values,
    // but the other 2 anchors have invalid absX/absY, so the new curr- needs to be updated
    for (int i = 0; i < 4; i++) {
      if (this.cornerAnchors[i].underMouse() && i != this.currActiveCornerAnchorId) {
        if (this.currActiveCornerAnchorId != -1) {
          this.prevActiveCornerAnchorId = this.currActiveCornerAnchorId;
        } else {
          // This should only get called once when first starting
          this.prevActiveCornerAnchorId = (i-1) % 4;
        }
        
        this.currActiveCornerAnchorId = i;
        
        Anchor prevAnchor = this.cornerAnchors[this.prevActiveCornerAnchorId];
        Anchor currAnchor = this.cornerAnchors[this.currActiveCornerAnchorId];
        
        float deltaRelativeX, deltaRelativeY, absX, absY;
        deltaRelativeX = prevAnchor.x - currAnchor.x;
        deltaRelativeY = prevAnchor.y - currAnchor.y;
        // cos(rotation) = (newAbsX - oldAbsX) / deltaX
        absX = (float) (deltaRelativeX * Math.cos(Math.toRadians(logo.rotation)) + prevAnchor.absX);
        absY = (float) (deltaRelativeY * Math.cos(Math.toRadians(logo.rotation)) + prevAnchor.absY);
        
        currAnchor.updateAbsPosition(absX, absY);
      }
    }
  }
  
  public void moveCornerToMouse() {
    int prevId, currId;
    prevId = this.prevActiveCornerAnchorId;
    currId = this.currActiveCornerAnchorId;
    
    Anchor prevAnchor = this.cornerAnchors[prevId];
    Anchor currAnchor = this.cornerAnchors[currId];
    
    float currAbsX, currAbsY, prevAbsX, prevAbsY, deltaAbsX, deltaAbsY;
    currAbsX = mouseX;
    currAbsY = mouseY;
    prevAbsX = prevAnchor.absX;
    prevAbsY = prevAnchor.absY;
    deltaAbsX = (currAbsX - prevAbsX) != 0 ? currAbsX - prevAbsX : 0.00001;
    deltaAbsY = currAbsY - prevAbsY;
    
    currAnchor.updateAbsPosition(currAbsX, currAbsY);
    
    this.z = (float) (Math.sqrt(Math.pow(deltaAbsX, 2) + Math.pow(deltaAbsY, 2)) / (((currId - prevId) % 2 == 1) ? 1.0 : Math.sqrt(2)));
  
    float quadrantOffset = ((currAbsX - prevAbsX) < 0 ? 1 : 0) * 180;
    float relativeRotation = (float) Math.toDegrees(Math.atan(deltaAbsY / deltaAbsX));
    float originalRelativeRotation = (prevId * 90) + (((currId - prevId - 1) % 4) * 45);
    
    this.rotation = quadrantOffset + relativeRotation - originalRelativeRotation;
    
    
    float degreeOffset = (currId * 90) + this.rotation + 45;
    this.x = (float) (this.z / Math.sqrt(2) * Math.cos(Math.toRadians(degreeOffset)) + currAbsX - (width / 2));
    this.y = (float) (this.z / Math.sqrt(2) * Math.sin(Math.toRadians(degreeOffset)) + currAbsY - (height / 2));
    
    if (printMessage) {
      System.out.println(String.format("oX: %.2f, oY: %.2f, rot: %.2f, prevId: %d, prevAbsX: %.2f, prevAbsY: %.2f, currId: %d, currAbsX: %.2f, currAbsY: %.2f",
                                      this.x, this.y, this.rotation,
                                      prevId, prevAbsX, prevAbsY,
                                      currId, currAbsX, currAbsY));
      printMessage = false;
    }
  }
  
  public void updateFromMouse() {
    if (this.grabbingCorner) {
      this.moveCornerToMouse();
      this.updateAnchorPositions();
    }
  }
}

private class Destination
{
  float x = 0;
  float y = 0;
  float rotation = 0;
  float z = 0;
}

ArrayList<Destination> destinations = new ArrayList<Destination>();

Logo logo;

void setup() {
  size(1000, 800);  
  rectMode(CENTER);
  ellipseMode(CENTER);
  textFont(createFont("Arial", inchToPix(.3f))); //sets the font to Arial that is 0.3" tall
  textAlign(CENTER);

  //don't change this! 
  border = inchToPix(2f); //padding of 1.0 inches

  for (int i=0; i<trialCount; i++) //don't change this! 
  {
    Destination d = new Destination();
    d.x = random(-width/2+border, width/2-border); //set a random x with some padding
    d.y = random(-height/2+border, height/2-border); //set a random y with some padding
    d.rotation = random(0, 360); //random rotation between 0 and 360
    int j = (int)random(20);
    d.z = ((j%12)+1)*inchToPix(.25f); //increasing size from .25 up to 3.0" 
    destinations.add(d);
    println("created target with " + d.x + "," + d.y + "," + d.rotation + "," + d.z);
  }

  Collections.shuffle(destinations); // randomize the order of the button; don't change this.
  
  submitButton = new SubmitButton();
  logo = new Logo();
}



void draw() {

  background(40); //background is dark grey
  fill(200);
  noStroke();

  //shouldn't really modify this printout code unless there is a really good reason to
  if (userDone)
  {
    text("User completed " + trialCount + " trials", width/2, inchToPix(.4f));
    text("User had " + errorCount + " error(s)", width/2, inchToPix(.4f)*2);
    text("User took " + (finishTime-startTime)/1000f/trialCount + " sec per destination", width/2, inchToPix(.4f)*3);
    text("User took " + ((finishTime-startTime)/1000f/trialCount+(errorCount*errorPenalty)) + " sec per destination inc. penalty", width/2, inchToPix(.4f)*4);
    return;
  }

  //===========DRAW DESTINATION SQUARES=================
  for (int i=trialIndex; i<trialCount; i++) // reduces over time
  {
    pushMatrix();
    translate(width/2, height/2); //center the drawing coordinates to the center of the screen
    Destination d = destinations.get(i);
    translate(d.x, d.y); //center the drawing coordinates to the center of the screen
    rotate(radians(d.rotation));
    noFill();
    strokeWeight(3f);
    if (trialIndex==i)
      stroke(255, 0, 0, 192); //set color to semi translucent
    else
      stroke(128, 128, 128, 128); //set color to semi translucent
    rect(0, 0, d.z, d.z);
    popMatrix();
  }

  //===========DRAW LOGO SQUARE=================
  logo.updateFromMouse();
  logo.drawLogo();
  
  //===========DRAW SUBMIT BUTTON=================
  submitButton.drawButton();

  //===========DRAW TRIAL INFO=================
  fill(255);
  text("Trial " + (trialIndex+1) + " of " +trialCount, width/2, inchToPix(.8f));
}

void mouseClicked() {
  printMessage = true;
  
  if (submitButton.underMouse()) {
    if (userDone==false && !checkForSuccess())
      errorCount++;

    trialIndex++; //and move on to next trial

    if (trialIndex==trialCount && userDone==false)
    {
      userDone = true;
      finishTime = millis();
    }
  }
}

void mousePressed()
{  
  if (startTime == 0) //start time on the instant of the first user click
  {
    startTime = millis();
    println("time started!");
  }
  
  System.out.println(String.format("Mouse clicked (adj): (%.2f, %.2f)", adjMouseX(), adjMouseY()));
  // If user is pressing close to center of Logo
  if (logo.mouseOverCorner()) {
    logo.grabbingCorner = true;
    logo.updateActiveCornerAnchor();
  }
}

void mouseDragged() {
  printMessage = true;
}


void mouseReleased()
{
  logo.grabbingCorner = false;
}

// Quadrants
//  2 | 1
//  3 | 4
//
// degree representation is inverted
//
//    270
//  180  0
//    90
//
// dist_0 = sqrt(opp_0^2 + adj_0^2)
// tan(theta_0) = opp_0 / adj_0
// theta_0 = toDegrees(arctan(opp_0 / adj_0))
// theta_1 = theta_0 + rotation
// check quadrant of theta_1 (0,90)/(90,180)/(180,270)/(270,360)
//    to determine sign of new x and y
// tan(theta_1) = opp_1 / adj_1
// opp_1 = 1.0 * tan(theta_1)
// dist_1 = sqrt(opp_1^2 + 1.0^2) = sqrt(tan(theta_1)^2 + 1.0)
// opp_2 = (opp_1 / dist_1) * dist_0 = (opp_1 * dist_0) / dist_1
//    do the second version to avoid underflowing
// adj_2 = (1.0 / dist_1) * dist_0 = dist_0 / dist_1
  
public float adjMouseX() {  
  // new_adj = dist_0 / dist_1
  // new_adj = sqrt(adjX^2 + adjY^2) / sqrt(tan(theta_1)^2 + 1.0)
  // new_adj = sqrt(adjX^2 + adjY^2) / sqrt(tan(toDegrees(arctan(adjY / adjX)) + rotation)^2 + 1.0)
  
  float adjX = mouseX - width/2 - logo.x;
  adjX = (adjX == 0) ? 0.00001 : adjX;
  // y-axis is inverted
  float adjY = mouseY - height/2 - logo.y;
  double dist_0 = Math.sqrt(Math.pow(adjX, 2) + Math.pow(adjY, 2));
  // % 360 only for quadrant check, doesn't affect tan value
  double theta_1 = ((adjX < 0 ? 180 : 0) + Math.toDegrees(Math.atan(adjY / adjX)) - logo.rotation) % 360;
  
  int sign = 1;
  if (90 <= theta_1 && theta_1 < 270) {
    sign = -1;
  }
  
  return (float) (dist_0 / Math.sqrt(Math.pow(Math.tan(Math.toRadians(theta_1)), 2) + 1.0)) * sign;
}

public float adjMouseY() {
  // new_opp = (opp_1 * dist_0) / dist_1
  // new_opp = tan(theta_1) * dist_0 / sqrt(tan(theta_1)^2 + 1.0)
  // new_opp = tan(theta_1) * adjMouseX
  
  float adjX = mouseX - width/2 - logo.x;
  adjX = (adjX == 0) ? 0.00001 : adjX;
  // y-axis is inverted
  float adjY = mouseY - height/2 - logo.y;
  double dist_0 = Math.sqrt(Math.pow(adjX, 2) + Math.pow(adjY, 2));
  // % 360 only for quadrant check, doesn't affect tan value
  double theta_1 = ((adjX < 0 ? 180 : 0) + Math.toDegrees(Math.atan(adjY / adjX)) - logo.rotation) % 360;
  
  return (float) Math.tan(Math.toRadians(theta_1)) * adjMouseX();
}

//probably shouldn't modify this, but email me if you want to for some good reason.
public boolean checkForSuccess()
{
  Destination d = destinations.get(trialIndex);	
  boolean closeDist = dist(d.x, d.y, logo.x, logo.y)<inchToPix(.05f); //has to be within +-0.05"
  boolean closeRotation = calculateDifferenceBetweenAngles(d.rotation, logo.rotation)<=5;
  boolean closeZ = abs(d.z - logo.z)<inchToPix(.05f); //has to be within +-0.05"	

  println("Close Enough Distance: " + closeDist + " (logo X/Y = " + d.x + "/" + d.y + ", destination X/Y = " + logo.x + "/" + logo.y +")");
  println("Close Enough Rotation: " + closeRotation + " (rot dist="+calculateDifferenceBetweenAngles(d.rotation, logo.rotation)+")");
  println("Close Enough Z: " +  closeZ + " (logo Z = " + d.z + ", destination Z = " + logo.z +")");
  println("Close enough all: " + (closeDist && closeRotation && closeZ));

  return closeDist && closeRotation && closeZ;
}

//utility function I include to calc diference between two angles
double calculateDifferenceBetweenAngles(float a1, float a2)
{
  double diff=abs(a1-a2);
  diff%=90;
  if (diff>45)
    return 90-diff;
  else
    return diff;
}

//utility function to convert inches into pixels based on screen PPI
float inchToPix(float inch)
{
  return inch*screenPPI;
}
