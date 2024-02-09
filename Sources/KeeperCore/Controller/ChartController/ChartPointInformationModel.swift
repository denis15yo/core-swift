import Foundation

public struct ChartPointInformationModel {
  public struct Diff {
    public enum Direction {
      case none
      case up
      case down
    }
    public let percent: String
    public let fiat: String
    public let direction: Direction
  }
  
  public let amount: String
  public let diff: Diff
  public let date: String
}
