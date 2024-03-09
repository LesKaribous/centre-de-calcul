import gab.opencv.*;
import org.opencv.aruco.*;
import org.opencv.core.*;
import org.opencv.imgproc.Imgproc;
import processing.video.*;
import java.util.List;
import java.util.ArrayList;

Capture video;
OpenCV opencv;

// Liste des IDs de tags ArUco que vous souhaitez détecter
int[] tagsToDetect = {1, 2, 3}; // Modifiez cette liste selon vos besoins

void setup() {
  size(640, 480);

  video = new Capture(this, 640, 480);
  opencv = new OpenCV(this, 640, 480);

  video.start();
}

void draw() {
  if (video.available()) {
    video.read();
  }
  image(video, 0, 0);

  opencv.loadImage(video);

  Mat gray = opencv.getGray();

  // Utiliser des marqueurs ArUco de type 4x4
  Dictionary dictionary = Aruco.getPredefinedDictionary(Aruco.DICT_4X4_50);
  MatOfInt markersIds = new MatOfInt();
  List<Mat> markersCorners = new ArrayList<>();
  DetectorParameters parameters = DetectorParameters.create();

  Aruco.detectMarkers(gray, dictionary, markersCorners, markersIds, parameters);

  // Convertir MatOfInt en ArrayList pour une manipulation facile
  ArrayList<Integer> idsList = new ArrayList<Integer>();
  if (markersIds.rows() > 0) {
    for (int i = 0; i < markersIds.rows(); i++) {
      idsList.add((int)markersIds.get(i, 0)[0]);
    }
  }

  stroke(0, 255, 0); // Couleur verte pour le cadre
  noFill(); // Pas de remplissage pour le cadre

  for (int i = 0; i < markersCorners.size(); i++) {
    int id = idsList.get(i);
    // Vérifier si le tag détecté est dans la liste des tags à détecter
    if (isTagToDetect(id)) {
      Mat corner = markersCorners.get(i);
      float[] points = new float[(int) corner.total() * 2];
      corner.get(0, 0, points);
      
      beginShape();
      for (int j = 0; j < points.length; j += 2) {
        vertex(points[j], points[j + 1]);
      }
      endShape(CLOSE);

      // Calculer le centre du tag pour afficher le texte
      float centerX = 0;
      float centerY = 0;
      for (int j = 0; j < points.length; j += 2) {
        centerX += points[j];
        centerY += points[j + 1];
      }
      centerX /= 4;
      centerY /= 4;

      fill(0, 255, 0); // Couleur verte pour le texte
      textSize(20);
      textAlign(CENTER, CENTER);
      text("ID: " + id + "\nPos: (" + (int)centerX + "," + (int)centerY + ")", centerX, centerY);
      noFill(); // Réinitialiser pour les cadres suivants
    }
  }
}

// Fonction pour vérifier si un tag spécifique doit être détecté
boolean isTagToDetect(int id) {
  for (int tagId : tagsToDetect) {
    if (id == tagId) {
      return true;
    }
  }
  return false;
}

void captureEvent(Capture c) {
  c.read();
}
