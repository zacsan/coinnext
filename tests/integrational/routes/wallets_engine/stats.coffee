require "./../../../helpers/spec_helper"

app = require "./../../../../wallets"
request = require "supertest"

describe "Stats Api", ->

  beforeEach (done)->
    GLOBAL.db.sequelize.sync({force: true}).complete ()->
      GLOBAL.db.sequelize.query("TRUNCATE TABLE #{GLOBAL.db.MarketStats.tableName}").complete ()->
        done()

  describe "POST /trade_stats", ()->
    now = Date.now()
    halfHour = 1800000
    endTime =  now - now % halfHour
    startTime = endTime - halfHour
    beforeEach (done)->
      orders = [
        {user_id: 1, type: "limit", action: "buy", buy_currency: "LTC", sell_currency: "BTC", amount: 10, unit_price: 0.1, status: "completed", published: true, close_time: startTime + 60000}
        
        {user_id: 1, type: "limit", action: "sell", buy_currency: "BTC", sell_currency: "LTC", amount: 1000, unit_price: 0.99999, status: "completed", published: true, close_time: startTime - 1}

        {user_id: 1, type: "limit", action: "sell", buy_currency: "BTC", sell_currency: "LTC", amount: 5, unit_price: 0.2, status: "completed", published: true, close_time: startTime + 130000}
        {user_id: 1, type: "limit", action: "sell", buy_currency: "BTC", sell_currency: "LTC", amount: 5, unit_price: 0.5, status: "completed", published: true, close_time: startTime + 150000}
        {user_id: 1, type: "limit", action: "sell", buy_currency: "BTC", sell_currency: "LTC", amount: 5, unit_price: 0.95, status: "completed", published: true, close_time: startTime + 170000}
        {user_id: 1, type: "limit", action: "sell", buy_currency: "BTC", sell_currency: "LTC", amount: 5, unit_price: 0.01, status: "completed", published: true, close_time: startTime + 190000}

        {user_id: 1, type: "limit", action: "sell", buy_currency: "BTC", sell_currency: "DOGE", amount: 300000000, unit_price: 0.5, status: "completed", published: true, close_time: startTime + 130000}
        {user_id: 1, type: "limit", action: "sell", buy_currency: "BTC", sell_currency: "DOGE", amount: 100000000, unit_price: 0.23, status: "completed", published: true, close_time: startTime + 150000}
        {user_id: 1, type: "limit", action: "sell", buy_currency: "BTC", sell_currency: "DOGE", amount: 3000000, unit_price: 0.56, status: "completed", published: true, close_time: startTime + 170000}
        {user_id: 1, type: "limit", action: "sell", buy_currency: "BTC", sell_currency: "DOGE", amount: 2000000, unit_price: 0.07, status: "completed", published: true, close_time: startTime + 190000}
      ]
      GLOBAL.db.Order.bulkCreate(orders).complete ()->
        done()

    it "returns 200 ok", (done)->
      request('http://localhost:6000')
      .post("/trade_stats")
      .send()
      .expect(200)
      .end (err, res)->
        res.body.message.should.eql "Trade stats aggregated from #{new Date(startTime)} to #{new Date(endTime)}"
        done()

    it "returns teh aggregated order result", (done)->
      request('http://localhost:6000')
      .post("/trade_stats")
      .send()
      .expect(200)
      .end (err, res)->
        expectedResult = [
          {
            type: "LTC_BTC"
            open_price: 0.2
            close_price: 0.01
            high_price: 0.95
            low_price: 0.01
            volume: 20
            start_time: new Date(startTime).toISOString()
            end_time: new Date(endTime).toISOString()
            id: null
          }
          {
            type: "DOGE_BTC"
            open_price: 0.5
            close_price: 0.07
            high_price: 0.56
            low_price: 0.07
            volume: 405000000
            start_time: new Date(startTime).toISOString()
            end_time: new Date(endTime).toISOString()
            id: null
          }
        ]
        res.body.result.should.eql expectedResult
        done()

    it "aggregates the orders from the last half an hour and persists them", (done)->
      request('http://localhost:6000')
      .post("/trade_stats")
      .send()
      .expect(200)
      .end ()->
        GLOBAL.db.TradeStats.findAll().complete (err, tradeStats)->
          expected =
            1: {id: 1, type: "LTC_BTC", open_price: 0.2, close_price: 0.01, high_price: 0.95, low_price: 0.01, volume: 20, start_time: new Date(startTime), end_time: new Date(endTime)}
            2: {id: 2, type: "DOGE_BTC", open_price: 0.5, close_price: 0.07, high_price: 0.56, low_price: 0.07, volume: 405000000, start_time: new Date(startTime), end_time: new Date(endTime)}
          for stat in tradeStats
            stat.values.should.containEql expected[stat.id]
          done()
