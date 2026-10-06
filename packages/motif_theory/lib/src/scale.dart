/// The scales a song (or a borrowed chord) can be written in, in the order the
/// key picker lists them.
enum Scale {
  major('Major', [0, 2, 4, 5, 7, 9, 11], 0),
  minor('Minor', [0, 2, 3, 5, 7, 8, 10], 5),
  dorian('Dorian', [0, 2, 3, 5, 7, 9, 10], 1),
  phrygian('Phrygian', [0, 1, 3, 5, 7, 8, 10], 2),
  lydian('Lydian', [0, 2, 4, 6, 7, 9, 11], 3),
  mixolydian('Mixolydian', [0, 2, 4, 5, 7, 9, 10], 4),
  locrian('Locrian', [0, 1, 3, 5, 6, 8, 10], 6),
  harmonicMinor('Harmonic Minor', [0, 2, 3, 5, 7, 8, 11], 5),
  phrygianDominant('Phrygian Dominant', [0, 1, 4, 5, 7, 8, 10], 2);

  const Scale(this.displayName, this.intervals, this.modeRotation);

  final String displayName;

  /// Semitones above the tonic for degrees 1–7.
  final List<int> intervals;

  /// How many degrees this scale (or, for harmonic minor and Phrygian
  /// dominant, its parent mode) is rotated from Ionian. Drives the
  /// diatonic-centric colour scheme and relative scale changes.
  final int modeRotation;

  /// True for the seven rotations of the major scale.
  bool get isDiatonicMode => this != harmonicMinor && this != phrygianDominant;

  /// Semitones above the tonic of scale degree [degree] (1-based), allowing
  /// degrees beyond 7 (degree 9 is degree 2 an octave up).
  int semitonesOf(int degree) {
    final zero = degree - 1;
    return intervals[zero % 7] + 12 * (zero ~/ 7);
  }
}
