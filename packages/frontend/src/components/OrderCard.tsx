import format from "date-fns/format"

import { FilteredOrderStructOutput } from "typechain-types/GasOrder"

import { COLOR_BY_STATUS } from "../constants/themeConstants"

import { Badge, Card, Text, Metric, Flex, ProgressBar, Icon, Button } from "@tremor/react"

import {
  ArrowPathIcon,
  CheckCircleIcon,
  PlayIcon,
  ExclamationTriangleIcon,
  XCircleIcon,
  StarIcon,
} from "@heroicons/react/24/outline"
import { useState } from "react"
import StatusBadge from "./StatusBadge"
import { redirect } from "next/navigation"
import Link from "next/link"

interface OrderCard extends FilteredOrderStructOutput {
  onFavorited(favorited: boolean): void
  className?: string
}

// @todo display order data
export default function OrderCard({
  id,
  order,
  gasBalance,
  status,
  gasCost,
  reward,
  guarantee,
  onFavorited = () => {},
  className = "",
}: OrderCard) {
  const checkIfIsFavorite = () => {
    let favOrders = localStorage.getItem("FAVORITE_ORDERS")
    if (favOrders === null) {
      return false
    }

    favOrders = JSON.parse(favOrders)
    const index = favOrders.indexOf(id.toString())
    if (index > -1) {
      return true
    } else {
      return false
    }
  }

  const [isFavorite, setIsFavorite] = useState<boolean>(checkIfIsFavorite())

  const addToFavorites = () => {
    let favOrders: any = localStorage.getItem("FAVORITE_ORDERS")
    if (favOrders !== null) {
      favOrders = JSON.parse(favOrders)
      favOrders.push(id.toString())
      localStorage.setItem("FAVORITE_ORDERS", JSON.stringify(favOrders))
    } else {
      const newArr = []
      newArr.push(id.toString())
      localStorage.setItem("FAVORITE_ORDERS", JSON.stringify(newArr))
    }

    setIsFavorite(true)
  }

  const removeFromFavorites = () => {
    let favOrders: any = localStorage.getItem("FAVORITE_ORDERS")
    if (favOrders !== null) {
      favOrders = JSON.parse(favOrders)
      const index = favOrders.indexOf(id.toString())
      if (index > -1) {
        favOrders.splice(index, 1)
        localStorage.setItem("FAVORITE_ORDERS", JSON.stringify(favOrders))
        setIsFavorite(false)
      }
    }
  }

  return (
    <Card className={className} decoration="top" decorationColor={COLOR_BY_STATUS[Number(status)]}>
      <Flex>
        <StatusBadge status={Number(status)} />
        {isFavorite ? (
          <Button
            onClick={() => {
              removeFromFavorites()
              onFavorited(false)
            }}
            color="amber"
            icon={StarIcon}
          ></Button>
        ) : (
          <Button
            onClick={() => {
              addToFavorites()
              onFavorited(true)
            }}
            variant="secondary"
            color="amber"
            icon={StarIcon}
          ></Button>
        )}
      </Flex>

      {/* @dev Order Id */}
      <Metric>#{id.toString()}</Metric>

      <Text>Manager: {order.manager}</Text>
      {/* @dev Order executionPeriodStart and executionPeriodDeadline */}
      {/*"yyyy.mm.dd hh:ss:mm"*/}
      <Text>
        Execution timeframe: {format(new Date(Number(order.executionPeriodStart) * 1000), "MMM d y, HH:mm:ss")} -{" "}
        {format(new Date(Number(order.executionPeriodDeadline) * 1000), "MMM d y, HH:mm:ss")}
      </Text>
      {/* @dev Order executionWindow */}
      <Text>Execution window: {order.executionWindow.toString()}</Text>
      {/* @dev Order executionWindow */}
      {/* @dev Order data, the details might be found in `TokenAmountWithDetails` structure */}
      {/* todo: how to get token 'symbol'? ${reward.amount} ${reward.symbol} */}
      <Text>{`Reward: ${reward.amount} ${reward.token}`}</Text>
      <Text>{`Gas Cost: ${gasCost.gasPrice} ${gasCost.token}`}</Text>
      <Text>{`Guarantee: ${guarantee.gasPrice} ${guarantee.token}`}</Text>
      {/* @dev Gas left (maxGas) */}
      <Flex className="mt-4">
        <Text>Used: 0 / {order.maxGas.toString()}</Text>
      </Flex>
      <ProgressBar value={32} className="mt-2" />
      <div className="flex flex-col gap-2 mt-4 md:flex-row-reverse">
        <Link href={`/order/${id}`}>
          <Button variant="secondary">Manage Order</Button>
        </Link>
      </div>
    </Card>
  )
}
