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

//These variables are for my example design. Your input code should modify/replace these!

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
    System.out.println(String.format("%.2f, %.2f, %.2f`, %.2f, %.2f", mouseX - width/2 - this.x, mouseY - height/2 - this.y, this.rotation, adjMouseX(), adjMouseY()));
    this.rotation += (float) Math.toDegrees(Math.atan(adjMouseY() / adjMouseX())) % 360;
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

  logo.updateFromMouse();

  //===========DRAW LOGO SQUARE=================
  logo.drawLogo();

  //===========DRAW EXAMPLE CONTROLS=================
  fill(255);
  scaffoldControlLogic(); //you are going to want to replace this!
  text("Trial " + (trialIndex+1) + " of " +trialCount, width/2, inchToPix(.8f));
}

//my example design for control, which is terrible
void scaffoldControlLogic()
{
  ////upper left corner, rotate counterclockwise
  //text("CCW", inchToPix(.4f), inchToPix(.4f));
  //if (mousePressed && dist(0, 0, mouseX, mouseY)<inchToPix(.8f))
  //  logoRotation--;

  ////upper right corner, rotate clockwise
  //text("CW", width-inchToPix(.4f), inchToPix(.4f));
  //if (mousePressed && dist(width, 0, mouseX, mouseY)<inchToPix(.8f))
  //  logoRotation++;

  ////lower left corner, decrease Z
  //text("-", inchToPix(.4f), height-inchToPix(.4f));
  //if (mousePressed && dist(0, height, mouseX, mouseY)<inchToPix(.8f))
  //  logoZ = constrain(logoZ-inchToPix(.02f), .01, inchToPix(4f)); //leave min and max alone!

  ////lower right corner, increase Z
  //text("+", width-inchToPix(.4f), height-inchToPix(.4f));
  //if (mousePressed && dist(width, height, mouseX, mouseY)<inchToPix(.8f))
  //  logoZ = constrain(logoZ+inchToPix(.02f), .01, inchToPix(4f)); //leave min and max alone! 

  ////left middle, move left
  //text("left", inchToPix(.4f), height/2);
  //if (mousePressed && dist(0, height/2, mouseX, mouseY)<inchToPix(.8f))
  //  logoX-=inchToPix(.02f);

  //text("right", width-inchToPix(.4f), height/2);
  //if (mousePressed && dist(width, height/2, mouseX, mouseY)<inchToPix(.8f))
  //  logoX+=inchToPix(.02f);

  //text("up", width/2, inchToPix(.4f));
  //if (mousePressed && dist(width/2, 0, mouseX, mouseY)<inchToPix(.8f))
  //  logoY-=inchToPix(.02f);

  //text("down", width/2, height-inchToPix(.4f));
  //if (mousePressed && dist(width/2, height, mouseX, mouseY)<inchToPix(.8f))
  //  logoY+=inchToPix(.02f);
}


void mousePressed()
{
  System.out.println(String.format("%.2f, %.2f, %.2f, %.2f", mouseX - width/2 - logo.x, mouseY - height/2 - logo.y, adjMouseX(), adjMouseY()));
  
  if (startTime == 0) //start time on the instant of the first user click
  {
    startTime = millis();
    println("time started!");
  }
  
  //pushMatrix();
  //translate(width/2, height/2); //center the drawing coordinates to the center of the screen
  //translate(logo.x, logo.y);  // adjust to make center of logo center of coordinates
  
  // If user is pressing close to center of Logo
  if (logo.mouseOverCenter()) {
    logo.dragging = true;
  } else if (logo.mouseOverCorner()) {
    logo.resizing = true;
  } else if (logo.mouseOverRotate()) {
    logo.rotating = true;
  }
  
  //popMatrix();
}


void mouseReleased()
{
  //check to see if user clicked middle of screen within 3 inches, which this code uses as a submit button
  //if (dist(width/2, height/2, mouseX, mouseY)<inchToPix(3f))
  //{
  //  if (userDone==false && !checkForSuccess())
  //    errorCount++;

  //  trialIndex++; //and move on to next trial

  //  if (trialIndex==trialCount && userDone==false)
  //  {
  //    userDone = true;
  //    finishTime = millis();
  //  }
  //}
  
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

public float adjMouseX() {
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
  
  // new_adj = dist_0 / dist_1
  // new_adj = sqrt(adjX^2 + adjY^2) / sqrt(tan(theta_1)^2 + 1.0)
  // new_adj = sqrt(adjX^2 + adjY^2) / sqrt(tan(toDegrees(arctan(adjY / adjX)) + rotation)^2 + 1.0)
  
  // I can maybe hack this to just use angle%90 to avoid quadrant stuff
  
  float adjX = mouseX - width/2 - logo.x;
  // y-axis is inverted
  float adjY = mouseY - height/2 - logo.y;
  double dist_0 = Math.sqrt(Math.pow(adjX, 2) + Math.pow(adjY, 2));
  // TODO: I'm not sure if this is correct with the %90
  //    If correct, theta_1 will always be in quadrant 1 with positive X and Y
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
  // TODO: I'm not sure if this is correct with the %90
  //    If correct, theta_1 will always be in quadrant 1 with positive X and Y
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
