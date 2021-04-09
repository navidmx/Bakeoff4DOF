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
  float x = 0;
  float y = 0;
  float z = 10f;
  
  public Anchor() { }
  
  public Anchor(float x, float y, float z) {
    this.x = x;
    this.y = y;
    this.z = z;
  }
  
  public void updateAll(float x, float y, float z) {
    this.x = x;
    this.y = y;
    this.z = z;
  }
  
  public void updatePosition(float x, float y) {
    this.x = x;
    this.y = y;
  }
  
  public void updateSize(float z) {
    this.z = z;
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
  
  Anchor centerAnchor;
  Anchor[] cornerAnchors = new Anchor[4];
  Anchor[] rotateAnchors = new Anchor[4];
  
  boolean dragging = false;
  boolean resizing = false;
  boolean rotating = false;
  
  public Logo() {
    for (int i = 0; i < 4; i++) {
      this.cornerAnchors[i] = new Anchor();
      this.rotateAnchors[i] = new Anchor();
    }
    
    this.updateAnchorPositions();
  }
  
  public void updateAnchorPositions() {
    float anchorSize = this.z / 4f;
    float anchorShift = this.z / 2f;
    
    // Anchor coordinates should be relative to Logo's center
    
    this.centerAnchor = new Anchor(0, 0, anchorSize);
    
    this.cornerAnchors[0].updateAll(-anchorShift, -anchorShift, anchorSize);
    this.cornerAnchors[1].updateAll(anchorShift, -anchorShift, anchorSize);
    this.cornerAnchors[2].updateAll(-anchorShift, anchorShift, anchorSize);
    this.cornerAnchors[3].updateAll(anchorShift, anchorShift, anchorSize);
    
    this.rotateAnchors[0].updateAll(0, -anchorShift * 1.5f, anchorSize);
    this.rotateAnchors[1].updateAll(anchorShift * 1.5f, 0, anchorSize);
    this.rotateAnchors[2].updateAll(0, anchorShift * 1.5f, anchorSize);
    this.rotateAnchors[3].updateAll(-anchorShift * 1.5f, 0, anchorSize);
  }
  
  public void drawLogo() {
    pushMatrix();
    translate(width/2 + this.x, height/2 + this.y); // center the screen coords on the logo coords 
    rotate(radians(this.rotation));
    noStroke();
    fill(60, 60, 192, 192);
    rect(0, 0, this.z, this.z);
    
    this.centerAnchor.drawAnchor();
    for (int i = 0; i < 4; i++) {
      this.cornerAnchors[i].drawAnchor();
      this.rotateAnchors[i].drawAnchor();
    }
    
    popMatrix();
  }
  
  public boolean mouseOverCenter() {
    return this.centerAnchor.underMouse();
  }
  
  public boolean mouseOverCorner() {
    boolean b = false;
    for (int i = 0; i < 4; i++) {
      b = b || this.cornerAnchors[i].underMouse();
    }
    return b;
  }
  
  public boolean mouseOverRotate() {
    boolean b = false;
    for (int i = 0; i < 4; i++) {
      b = b || this.rotateAnchors[i].underMouse();
    }
    return b;
  }
  
  public void moveToMouse() {
    // This doesn't use adjMouseX because otherwise wouldn't move
    // Just adjusts mouse coords repective to center of screen
    // Uses "absolute" positioning (from center)
    this.x = mouseX - width/2;
    this.y = mouseY - height/2;
  }
  
  public void resizeToMouse() {
    // dist_logo_center_to_mouse^2 = (z/2)^2 + (z/2)^2
    // (dist_logo_center_to_mouse^2) / 2 = (z/2)^2
    // sqrt((dist_logo_center_to_mouse^2) / 2) = z / 2
    // 2 * sqrt((dist_logo_center_to_mouse^2) / 2) = z
    float diag_dist = dist(0, 0, adjMouseX(), adjMouseY());
    this.z = (float) (2 * Math.sqrt(Math.pow(diag_dist, 2) / 2.0));
    this.z = constrain(this.z, .01, inchToPix(4f));
  }
  
  public void rotateToMouse() {
    // tan(theta) = opposite / adjacent
    // tan(rotation) = adjMouseY / adjMouseX
    // rotation = arctan(adjMouseY / adjMouseX)
    // arctan returns radians, we assume degrees
    
    // Want rotation to adjust to make mouse inline with axis
    // (i.e. diff between rotation and (mouseX-width/2-this.x, mouseY-height/2-this.y) goes to 0)
    // Also makes adjMouseY go to 0 and adjMouseX is dist(0,0,mouseX-width/2-this.x, mouseY-height/2-this.y)
    this.rotation += (float) Math.toDegrees(Math.atan(adjMouseY() / adjMouseX()));
    
    // Glitch happens when adjMouseY becomes large relative to adjMouseX
    // Program is trying to keep adjMouseY low, so makes big jump in this scenario
    // This happens when crossing an axis boundary
    // More work needs to be done to figure out the specifics, but it isn't too problematic
  }
  
  public void updateFromMouse() {
    if (this.dragging) {
      this.moveToMouse();
    } else if (this.resizing) {
      this.resizeToMouse();
      this.updateAnchorPositions();
    } else if (this.rotating) {
      this.rotateToMouse();
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

Logo logo = new Logo();

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
  
  // If user is pressing close to center of Logo
  if (logo.mouseOverCenter()) {
    logo.dragging = true;
  } else if (logo.mouseOverCorner()) {
    logo.resizing = true;
  } else if (logo.mouseOverRotate()) {
    logo.rotating = true;
  }
}


void mouseReleased()
{
  logo.dragging = false;
  logo.resizing = false;
  logo.rotating = false;
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
  // y-axis is inverted
  float adjY = mouseY - height/2 - logo.y;
  double dist_0 = Math.sqrt(Math.pow(adjX, 2) + Math.pow(adjY, 2));
  // % 360 only for quadrant check, doesn't affect tan value
  double theta_1 = (Math.toDegrees(Math.atan(adjY / adjX)) - logo.rotation) % 360;
  
  int sign = 1;
  if (90 <= theta_1 && theta_1 < 270) {
    sign = -1;
  }
  
  return (float) (dist_0 / Math.sqrt(Math.pow(Math.tan(Math.toRadians(theta_1)), 2) + 1.0)) * sign;
}

public float adjMouseY() {
  // new_opp = (opp_1 * dist_0) / dist_1
  // new_opp = tan(theta_1) * dist_0 / sqrt(tan(theta_1)^2 + 1.0)
  
  float adjX = mouseX - width/2 - logo.x;
  // y-axis is inverted
  float adjY = mouseY - height/2 - logo.y;
  double dist_0 = Math.sqrt(Math.pow(adjX, 2) + Math.pow(adjY, 2));
  // % 360 only for quadrant check, doesn't affect tan value
  double theta_1 = (Math.toDegrees(Math.atan(adjY / adjX)) - logo.rotation) % 360;
  
  int signX = 1;
  if (90 <= theta_1 && theta_1 < 270) {
    signX = -1;
  }
  
  int signY = 1;
  // y-axis is inverted and degree representation is inverted, so quadrants 3 and 4 are negative
  if (180 <= theta_1 && theta_1 < 360) {
    signY = -1;
  }
  
  return (float) Math.tan(Math.toRadians(theta_1)) * adjMouseX() * signX * signY;
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
