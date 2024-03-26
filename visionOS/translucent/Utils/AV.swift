import Foundation
import AVFAudio

func setupAudio() {
  try? AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
  try? AVAudioSession.sharedInstance().setIntendedSpatialExperience(.fixed(soundStageSize: .automatic))
  try? AVAudioSession.sharedInstance().setActive(true)
}
