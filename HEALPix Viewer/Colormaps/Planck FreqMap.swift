//
//  Planck FreqMap.swift
//  HEALPix Viewer
//
//  Created by Andrei Frolov on 2022-11-02.
//

import Foundation
import MetalKit

let Planck_FreqMap_LUT = [
    SIMD4<Float>(0.0/255.0, 0.0/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(0.769231/255.0, 1.53846/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(1.53846/255.0, 3.07692/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(2.30769/255.0, 4.61538/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(3.07692/255.0, 6.15385/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(3.84615/255.0, 7.69231/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(4.61538/255.0, 9.23077/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(5.38462/255.0, 10.7692/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(6.15385/255.0, 12.3077/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(6.92308/255.0, 13.8462/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(7.69231/255.0, 15.3846/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(8.46154/255.0, 16.9231/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(9.23077/255.0, 18.4615/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(10.0/255.0, 20.0/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(11.5385/255.0, 32.6154/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(13.0769/255.0, 45.2308/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(14.6154/255.0, 57.8462/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(16.1538/255.0, 70.4615/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(17.6923/255.0, 83.0769/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(19.2308/255.0, 95.6923/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(20.7692/255.0, 108.308/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(22.3077/255.0, 120.923/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(23.8462/255.0, 133.538/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(25.3846/255.0, 146.154/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(26.9231/255.0, 158.769/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(28.4615/255.0, 171.385/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(30.0/255.0, 184.0/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(33.8462/255.0, 187.923/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(37.6923/255.0, 191.846/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(41.5385/255.0, 195.769/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(45.3846/255.0, 199.692/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(49.2308/255.0, 203.615/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(53.0769/255.0, 207.538/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(56.9231/255.0, 211.462/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(60.7692/255.0, 215.385/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(64.6154/255.0, 219.308/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(68.4615/255.0, 223.231/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(72.3077/255.0, 227.154/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(76.1538/255.0, 231.077/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(80.0/255.0, 235.0/255.0, 255.0/255.0, 1.0),
    SIMD4<Float>(88.5385/255.0, 235.308/255.0, 254.615/255.0, 1.0),
    SIMD4<Float>(97.0769/255.0, 235.615/255.0, 254.231/255.0, 1.0),
    SIMD4<Float>(105.615/255.0, 235.923/255.0, 253.846/255.0, 1.0),
    SIMD4<Float>(114.154/255.0, 236.231/255.0, 253.462/255.0, 1.0),
    SIMD4<Float>(122.692/255.0, 236.538/255.0, 253.077/255.0, 1.0),
    SIMD4<Float>(131.231/255.0, 236.846/255.0, 252.692/255.0, 1.0),
    SIMD4<Float>(139.769/255.0, 237.154/255.0, 252.308/255.0, 1.0),
    SIMD4<Float>(148.308/255.0, 237.462/255.0, 251.923/255.0, 1.0),
    SIMD4<Float>(156.846/255.0, 237.769/255.0, 251.538/255.0, 1.0),
    SIMD4<Float>(165.385/255.0, 238.077/255.0, 251.154/255.0, 1.0),
    SIMD4<Float>(173.923/255.0, 238.385/255.0, 250.769/255.0, 1.0),
    SIMD4<Float>(182.462/255.0, 238.692/255.0, 250.385/255.0, 1.0),
    SIMD4<Float>(191.0/255.0, 239.0/255.0, 250.0/255.0, 1.0),
    SIMD4<Float>(193.846/255.0, 239.077/255.0, 249.615/255.0, 1.0),
    SIMD4<Float>(196.692/255.0, 239.154/255.0, 249.231/255.0, 1.0),
    SIMD4<Float>(199.538/255.0, 239.231/255.0, 248.846/255.0, 1.0),
    SIMD4<Float>(202.385/255.0, 239.308/255.0, 248.462/255.0, 1.0),
    SIMD4<Float>(205.231/255.0, 239.385/255.0, 248.077/255.0, 1.0),
    SIMD4<Float>(208.077/255.0, 239.462/255.0, 247.692/255.0, 1.0),
    SIMD4<Float>(210.923/255.0, 239.538/255.0, 247.308/255.0, 1.0),
    SIMD4<Float>(213.769/255.0, 239.615/255.0, 246.923/255.0, 1.0),
    SIMD4<Float>(216.615/255.0, 239.692/255.0, 246.538/255.0, 1.0),
    SIMD4<Float>(219.462/255.0, 239.769/255.0, 246.154/255.0, 1.0),
    SIMD4<Float>(222.308/255.0, 239.846/255.0, 245.769/255.0, 1.0),
    SIMD4<Float>(225.154/255.0, 239.923/255.0, 245.385/255.0, 1.0),
    SIMD4<Float>(228.0/255.0, 240.0/255.0, 245.0/255.0, 1.0),
    SIMD4<Float>(229.182/255.0, 240.091/255.0, 242.0/255.0, 1.0),
    SIMD4<Float>(230.364/255.0, 240.182/255.0, 239.0/255.0, 1.0),
    SIMD4<Float>(231.545/255.0, 240.273/255.0, 236.0/255.0, 1.0),
    SIMD4<Float>(232.727/255.0, 240.364/255.0, 233.0/255.0, 1.0),
    SIMD4<Float>(233.909/255.0, 240.455/255.0, 230.0/255.0, 1.0),
    SIMD4<Float>(235.091/255.0, 240.545/255.0, 227.0/255.0, 1.0),
    SIMD4<Float>(236.273/255.0, 240.636/255.0, 224.0/255.0, 1.0),
    SIMD4<Float>(237.455/255.0, 240.727/255.0, 221.0/255.0, 1.0),
    SIMD4<Float>(238.636/255.0, 240.818/255.0, 218.0/255.0, 1.0),
    SIMD4<Float>(239.818/255.0, 240.909/255.0, 215.0/255.0, 1.0),
    SIMD4<Float>(241.0/255.0, 241.0/255.0, 212.0/255.0, 1.0),
    SIMD4<Float>(241.0/255.0, 241.0/255.0, 212.0/255.0, 1.0),
    SIMD4<Float>(241.364/255.0, 240.909/255.0, 208.636/255.0, 1.0),
    SIMD4<Float>(241.727/255.0, 240.818/255.0, 205.273/255.0, 1.0),
    SIMD4<Float>(242.091/255.0, 240.727/255.0, 201.909/255.0, 1.0),
    SIMD4<Float>(242.455/255.0, 240.636/255.0, 198.545/255.0, 1.0),
    SIMD4<Float>(242.818/255.0, 240.545/255.0, 195.182/255.0, 1.0),
    SIMD4<Float>(243.182/255.0, 240.455/255.0, 191.818/255.0, 1.0),
    SIMD4<Float>(243.545/255.0, 240.364/255.0, 188.455/255.0, 1.0),
    SIMD4<Float>(243.909/255.0, 240.273/255.0, 185.091/255.0, 1.0),
    SIMD4<Float>(244.273/255.0, 240.182/255.0, 181.727/255.0, 1.0),
    SIMD4<Float>(244.636/255.0, 240.091/255.0, 178.364/255.0, 1.0),
    SIMD4<Float>(245.0/255.0, 240.0/255.0, 175.0/255.0, 1.0),
    SIMD4<Float>(245.231/255.0, 239.615/255.0, 171.538/255.0, 1.0),
    SIMD4<Float>(245.462/255.0, 239.231/255.0, 168.077/255.0, 1.0),
    SIMD4<Float>(245.692/255.0, 238.846/255.0, 164.615/255.0, 1.0),
    SIMD4<Float>(245.923/255.0, 238.462/255.0, 161.154/255.0, 1.0),
    SIMD4<Float>(246.154/255.0, 238.077/255.0, 157.692/255.0, 1.0),
    SIMD4<Float>(246.385/255.0, 237.692/255.0, 154.231/255.0, 1.0),
    SIMD4<Float>(246.615/255.0, 237.308/255.0, 150.769/255.0, 1.0),
    SIMD4<Float>(246.846/255.0, 236.923/255.0, 147.308/255.0, 1.0),
    SIMD4<Float>(247.077/255.0, 236.538/255.0, 143.846/255.0, 1.0),
    SIMD4<Float>(247.308/255.0, 236.154/255.0, 140.385/255.0, 1.0),
    SIMD4<Float>(247.538/255.0, 235.769/255.0, 136.923/255.0, 1.0),
    SIMD4<Float>(247.769/255.0, 235.385/255.0, 133.462/255.0, 1.0),
    SIMD4<Float>(248.0/255.0, 235.0/255.0, 130.0/255.0, 1.0),
    SIMD4<Float>(248.146/255.0, 232.615/255.0, 122.942/255.0, 1.0),
    SIMD4<Float>(248.292/255.0, 230.231/255.0, 115.885/255.0, 1.0),
    SIMD4<Float>(248.438/255.0, 227.846/255.0, 108.827/255.0, 1.0),
    SIMD4<Float>(248.585/255.0, 225.462/255.0, 101.769/255.0, 1.0),
    SIMD4<Float>(248.731/255.0, 223.077/255.0, 94.7115/255.0, 1.0),
    SIMD4<Float>(248.877/255.0, 220.692/255.0, 87.6539/255.0, 1.0),
    SIMD4<Float>(249.023/255.0, 218.308/255.0, 80.5962/255.0, 1.0),
    SIMD4<Float>(249.169/255.0, 215.923/255.0, 73.5385/255.0, 1.0),
    SIMD4<Float>(249.315/255.0, 213.538/255.0, 66.4808/255.0, 1.0),
    SIMD4<Float>(249.462/255.0, 211.154/255.0, 59.4231/255.0, 1.0),
    SIMD4<Float>(249.608/255.0, 208.769/255.0, 52.3654/255.0, 1.0),
    SIMD4<Float>(249.754/255.0, 206.385/255.0, 45.3077/255.0, 1.0),
    SIMD4<Float>(249.9/255.0, 204.0/255.0, 38.25/255.0, 1.0),
    SIMD4<Float>(249.312/255.0, 200.077/255.0, 36.2885/255.0, 1.0),
    SIMD4<Float>(248.723/255.0, 196.154/255.0, 34.3269/255.0, 1.0),
    SIMD4<Float>(248.135/255.0, 192.231/255.0, 32.3654/255.0, 1.0),
    SIMD4<Float>(247.546/255.0, 188.308/255.0, 30.4038/255.0, 1.0),
    SIMD4<Float>(246.958/255.0, 184.385/255.0, 28.4423/255.0, 1.0),
    SIMD4<Float>(246.369/255.0, 180.462/255.0, 26.4808/255.0, 1.0),
    SIMD4<Float>(245.781/255.0, 176.538/255.0, 24.5192/255.0, 1.0),
    SIMD4<Float>(245.192/255.0, 172.615/255.0, 22.5577/255.0, 1.0),
    SIMD4<Float>(244.604/255.0, 168.692/255.0, 20.5962/255.0, 1.0),
    SIMD4<Float>(244.015/255.0, 164.769/255.0, 18.6346/255.0, 1.0),
    SIMD4<Float>(243.427/255.0, 160.846/255.0, 16.6731/255.0, 1.0),
    SIMD4<Float>(242.838/255.0, 156.923/255.0, 14.7115/255.0, 1.0),
    SIMD4<Float>(242.25/255.0, 153.0/255.0, 12.75/255.0, 1.0),
    SIMD4<Float>(239.308/255.0, 147.115/255.0, 11.7692/255.0, 1.0),
    SIMD4<Float>(236.365/255.0, 141.231/255.0, 10.7885/255.0, 1.0),
    SIMD4<Float>(233.423/255.0, 135.346/255.0, 9.80769/255.0, 1.0),
    SIMD4<Float>(230.481/255.0, 129.462/255.0, 8.82692/255.0, 1.0),
    SIMD4<Float>(227.538/255.0, 123.577/255.0, 7.84615/255.0, 1.0),
    SIMD4<Float>(224.596/255.0, 117.692/255.0, 6.86539/255.0, 1.0),
    SIMD4<Float>(221.654/255.0, 111.808/255.0, 5.88461/255.0, 1.0),
    SIMD4<Float>(218.712/255.0, 105.923/255.0, 4.90385/255.0, 1.0),
    SIMD4<Float>(215.769/255.0, 100.038/255.0, 3.92308/255.0, 1.0),
    SIMD4<Float>(212.827/255.0, 94.1538/255.0, 2.94231/255.0, 1.0),
    SIMD4<Float>(209.885/255.0, 88.2692/255.0, 1.96154/255.0, 1.0),
    SIMD4<Float>(206.942/255.0, 82.3846/255.0, 0.980769/255.0, 1.0),
    SIMD4<Float>(204.0/255.0, 76.5/255.0, 0.0/255.0, 1.0),
    SIMD4<Float>(201.0/255.0, 73.0769/255.0, 2.46154/255.0, 1.0),
    SIMD4<Float>(198.0/255.0, 69.6538/255.0, 4.92308/255.0, 1.0),
    SIMD4<Float>(195.0/255.0, 66.2308/255.0, 7.38462/255.0, 1.0),
    SIMD4<Float>(192.0/255.0, 62.8077/255.0, 9.84616/255.0, 1.0),
    SIMD4<Float>(189.0/255.0, 59.3846/255.0, 12.3077/255.0, 1.0),
    SIMD4<Float>(186.0/255.0, 55.9615/255.0, 14.7692/255.0, 1.0),
    SIMD4<Float>(183.0/255.0, 52.5385/255.0, 17.2308/255.0, 1.0),
    SIMD4<Float>(180.0/255.0, 49.1154/255.0, 19.6923/255.0, 1.0),
    SIMD4<Float>(177.0/255.0, 45.6923/255.0, 22.1538/255.0, 1.0),
    SIMD4<Float>(174.0/255.0, 42.2692/255.0, 24.6154/255.0, 1.0),
    SIMD4<Float>(171.0/255.0, 38.8462/255.0, 27.0769/255.0, 1.0),
    SIMD4<Float>(168.0/255.0, 35.4231/255.0, 29.5385/255.0, 1.0),
    SIMD4<Float>(165.0/255.0, 32.0/255.0, 32.0/255.0, 1.0),
    SIMD4<Float>(161.077/255.0, 29.5385/255.0, 32.0/255.0, 1.0),
    SIMD4<Float>(157.154/255.0, 27.0769/255.0, 32.0/255.0, 1.0),
    SIMD4<Float>(153.231/255.0, 24.6154/255.0, 32.0/255.0, 1.0),
    SIMD4<Float>(149.308/255.0, 22.1538/255.0, 32.0/255.0, 1.0),
    SIMD4<Float>(145.385/255.0, 19.6923/255.0, 32.0/255.0, 1.0),
    SIMD4<Float>(141.462/255.0, 17.2308/255.0, 32.0/255.0, 1.0),
    SIMD4<Float>(137.538/255.0, 14.7692/255.0, 32.0/255.0, 1.0),
    SIMD4<Float>(133.615/255.0, 12.3077/255.0, 32.0/255.0, 1.0),
    SIMD4<Float>(129.692/255.0, 9.84615/255.0, 32.0/255.0, 1.0),
    SIMD4<Float>(125.769/255.0, 7.38462/255.0, 32.0/255.0, 1.0),
    SIMD4<Float>(121.846/255.0, 4.92308/255.0, 32.0/255.0, 1.0),
    SIMD4<Float>(117.923/255.0, 2.46154/255.0, 32.0/255.0, 1.0),
    SIMD4<Float>(114.0/255.0, 0.0/255.0, 32.0/255.0, 1.0),
    SIMD4<Float>(115.038/255.0, 9.80769/255.0, 41.3077/255.0, 1.0),
    SIMD4<Float>(116.077/255.0, 19.6154/255.0, 50.6154/255.0, 1.0),
    SIMD4<Float>(117.115/255.0, 29.4231/255.0, 59.9231/255.0, 1.0),
    SIMD4<Float>(118.154/255.0, 39.2308/255.0, 69.2308/255.0, 1.0),
    SIMD4<Float>(119.192/255.0, 49.0385/255.0, 78.5385/255.0, 1.0),
    SIMD4<Float>(120.231/255.0, 58.8462/255.0, 87.8462/255.0, 1.0),
    SIMD4<Float>(121.269/255.0, 68.6538/255.0, 97.1539/255.0, 1.0),
    SIMD4<Float>(122.308/255.0, 78.4615/255.0, 106.462/255.0, 1.0),
    SIMD4<Float>(123.346/255.0, 88.2692/255.0, 115.769/255.0, 1.0),
    SIMD4<Float>(124.385/255.0, 98.0769/255.0, 125.077/255.0, 1.0),
    SIMD4<Float>(125.423/255.0, 107.885/255.0, 134.385/255.0, 1.0),
    SIMD4<Float>(126.462/255.0, 117.692/255.0, 143.692/255.0, 1.0),
    SIMD4<Float>(127.5/255.0, 127.5/255.0, 153.0/255.0, 1.0),
    SIMD4<Float>(131.423/255.0, 131.423/255.0, 156.923/255.0, 1.0),
    SIMD4<Float>(135.346/255.0, 135.346/255.0, 160.846/255.0, 1.0),
    SIMD4<Float>(139.269/255.0, 139.269/255.0, 164.769/255.0, 1.0),
    SIMD4<Float>(143.192/255.0, 143.192/255.0, 168.692/255.0, 1.0),
    SIMD4<Float>(147.115/255.0, 147.115/255.0, 172.615/255.0, 1.0),
    SIMD4<Float>(151.038/255.0, 151.038/255.0, 176.538/255.0, 1.0),
    SIMD4<Float>(154.962/255.0, 154.962/255.0, 180.462/255.0, 1.0),
    SIMD4<Float>(158.885/255.0, 158.885/255.0, 184.385/255.0, 1.0),
    SIMD4<Float>(162.808/255.0, 162.808/255.0, 188.308/255.0, 1.0),
    SIMD4<Float>(166.731/255.0, 166.731/255.0, 192.231/255.0, 1.0),
    SIMD4<Float>(170.654/255.0, 170.654/255.0, 196.154/255.0, 1.0),
    SIMD4<Float>(174.577/255.0, 174.577/255.0, 200.077/255.0, 1.0),
    SIMD4<Float>(178.5/255.0, 178.5/255.0, 204.0/255.0, 1.0),
    SIMD4<Float>(180.462/255.0, 180.462/255.0, 205.962/255.0, 1.0),
    SIMD4<Float>(182.423/255.0, 182.423/255.0, 207.923/255.0, 1.0),
    SIMD4<Float>(184.385/255.0, 184.385/255.0, 209.885/255.0, 1.0),
    SIMD4<Float>(186.346/255.0, 186.346/255.0, 211.846/255.0, 1.0),
    SIMD4<Float>(188.308/255.0, 188.308/255.0, 213.808/255.0, 1.0),
    SIMD4<Float>(190.269/255.0, 190.269/255.0, 215.769/255.0, 1.0),
    SIMD4<Float>(192.231/255.0, 192.231/255.0, 217.731/255.0, 1.0),
    SIMD4<Float>(194.192/255.0, 194.192/255.0, 219.692/255.0, 1.0),
    SIMD4<Float>(196.154/255.0, 196.154/255.0, 221.654/255.0, 1.0),
    SIMD4<Float>(198.115/255.0, 198.115/255.0, 223.615/255.0, 1.0),
    SIMD4<Float>(200.077/255.0, 200.077/255.0, 225.577/255.0, 1.0),
    SIMD4<Float>(202.038/255.0, 202.038/255.0, 227.538/255.0, 1.0),
    SIMD4<Float>(204.0/255.0, 204.0/255.0, 229.5/255.0, 1.0),
    SIMD4<Float>(205.962/255.0, 205.962/255.0, 230.481/255.0, 1.0),
    SIMD4<Float>(207.923/255.0, 207.923/255.0, 231.462/255.0, 1.0),
    SIMD4<Float>(209.885/255.0, 209.885/255.0, 232.442/255.0, 1.0),
    SIMD4<Float>(211.846/255.0, 211.846/255.0, 233.423/255.0, 1.0),
    SIMD4<Float>(213.808/255.0, 213.808/255.0, 234.404/255.0, 1.0),
    SIMD4<Float>(215.769/255.0, 215.769/255.0, 235.385/255.0, 1.0),
    SIMD4<Float>(217.731/255.0, 217.731/255.0, 236.365/255.0, 1.0),
    SIMD4<Float>(219.692/255.0, 219.692/255.0, 237.346/255.0, 1.0),
    SIMD4<Float>(221.654/255.0, 221.654/255.0, 238.327/255.0, 1.0),
    SIMD4<Float>(223.615/255.0, 223.615/255.0, 239.308/255.0, 1.0),
    SIMD4<Float>(225.577/255.0, 225.577/255.0, 240.288/255.0, 1.0),
    SIMD4<Float>(227.538/255.0, 227.538/255.0, 241.269/255.0, 1.0),
    SIMD4<Float>(229.5/255.0, 229.5/255.0, 242.25/255.0, 1.0),
    SIMD4<Float>(230.481/255.0, 230.481/255.0, 242.838/255.0, 1.0),
    SIMD4<Float>(231.462/255.0, 231.462/255.0, 243.427/255.0, 1.0),
    SIMD4<Float>(232.442/255.0, 232.442/255.0, 244.015/255.0, 1.0),
    SIMD4<Float>(233.423/255.0, 233.423/255.0, 244.604/255.0, 1.0),
    SIMD4<Float>(234.404/255.0, 234.404/255.0, 245.192/255.0, 1.0),
    SIMD4<Float>(235.385/255.0, 235.385/255.0, 245.781/255.0, 1.0),
    SIMD4<Float>(236.365/255.0, 236.365/255.0, 246.369/255.0, 1.0),
    SIMD4<Float>(237.346/255.0, 237.346/255.0, 246.958/255.0, 1.0),
    SIMD4<Float>(238.327/255.0, 238.327/255.0, 247.546/255.0, 1.0),
    SIMD4<Float>(239.308/255.0, 239.308/255.0, 248.135/255.0, 1.0),
    SIMD4<Float>(240.288/255.0, 240.288/255.0, 248.723/255.0, 1.0),
    SIMD4<Float>(241.269/255.0, 241.269/255.0, 249.312/255.0, 1.0),
    SIMD4<Float>(242.25/255.0, 242.25/255.0, 249.9/255.0, 1.0),
    SIMD4<Float>(242.642/255.0, 242.642/255.0, 250.096/255.0, 1.0),
    SIMD4<Float>(243.035/255.0, 243.035/255.0, 250.292/255.0, 1.0),
    SIMD4<Float>(243.427/255.0, 243.427/255.0, 250.488/255.0, 1.0),
    SIMD4<Float>(243.819/255.0, 243.819/255.0, 250.685/255.0, 1.0),
    SIMD4<Float>(244.212/255.0, 244.212/255.0, 250.881/255.0, 1.0),
    SIMD4<Float>(244.604/255.0, 244.604/255.0, 251.077/255.0, 1.0),
    SIMD4<Float>(244.996/255.0, 244.996/255.0, 251.273/255.0, 1.0),
    SIMD4<Float>(245.388/255.0, 245.388/255.0, 251.469/255.0, 1.0),
    SIMD4<Float>(245.781/255.0, 245.781/255.0, 251.665/255.0, 1.0),
    SIMD4<Float>(246.173/255.0, 246.173/255.0, 251.862/255.0, 1.0),
    SIMD4<Float>(246.565/255.0, 246.565/255.0, 252.058/255.0, 1.0),
    SIMD4<Float>(246.958/255.0, 246.958/255.0, 252.254/255.0, 1.0),
    SIMD4<Float>(247.35/255.0, 247.35/255.0, 252.45/255.0, 1.0),
    SIMD4<Float>(247.814/255.0, 247.814/255.0, 252.682/255.0, 1.0),
    SIMD4<Float>(248.277/255.0, 248.277/255.0, 252.914/255.0, 1.0),
    SIMD4<Float>(248.741/255.0, 248.741/255.0, 253.145/255.0, 1.0),
    SIMD4<Float>(249.205/255.0, 249.205/255.0, 253.377/255.0, 1.0),
    SIMD4<Float>(249.668/255.0, 249.668/255.0, 253.609/255.0, 1.0),
    SIMD4<Float>(250.132/255.0, 250.132/255.0, 253.841/255.0, 1.0),
    SIMD4<Float>(250.595/255.0, 250.595/255.0, 254.073/255.0, 1.0),
    SIMD4<Float>(251.059/255.0, 251.059/255.0, 254.305/255.0, 1.0),
    SIMD4<Float>(251.523/255.0, 251.523/255.0, 254.536/255.0, 1.0),
    SIMD4<Float>(251.986/255.0, 251.986/255.0, 254.768/255.0, 1.0),
    SIMD4<Float>(252.45/255.0, 252.45/255.0, 255.0/255.0, 1.0)
]