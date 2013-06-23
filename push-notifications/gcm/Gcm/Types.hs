-- GSoC 2013 - Communicating with mobile devices.
{-# LANGUAGE FlexibleContexts #-}
-- | This Module define the main data types for sending Push Notifications through Google Cloud Messaging.
module Gcm.Types
    ( GCMAppConfig(..)
    , GCMmessage(..)
    , GCMresult(..)
    , MRes(..)
    , RegId
    , Notif_key
    , Notif_key_name
    ) where


import Gcm.Constants
import Data.Default
import Data.Aeson.Types
import Data.Text
import Control.Monad.Writer


-- | 'GCMAppConfig' represents the main necessary information for sending notifications through GCM.
data GCMAppConfig = GCMAppConfig
    {   apiKey :: String
    ,   projectId :: String
    }   deriving Show


type RegId = String
type Notif_key = String
type Notif_key_name = String


-- | 'GCMmessage' represents a message to be sent through GCM.
data GCMmessage = GCMmessage
    {   registration_ids :: Maybe [RegId]
    ,   notification_key :: Maybe Notif_key -- Need to be continued, this is a new option added in the Google IO 2013
    ,   notification_key_name :: Maybe Notif_key_name
    ,   collapse_key :: String
    ,   data_object :: Maybe Object
    ,   delay_while_idle :: Bool
    ,   time_to_live :: Maybe Int
    ,   restricted_package_name :: String
    ,   dry_run :: Bool
    } deriving Show

instance Default GCMmessage where
    def = GCMmessage {
        registration_ids = Nothing
    ,   notification_key = Nothing
    ,   notification_key_name = Nothing
    ,   collapse_key = []
    ,   data_object = Nothing
    ,   delay_while_idle = False
    ,   time_to_live = Nothing
    ,   restricted_package_name = []
    ,   dry_run = False
    }


data MRes = GCMError String
          | GCMOk String
            deriving Show


-- | 'GCMresult' represents information about messages after a communication with GCM Servers.
data GCMresult = GCMresult
    {   multicast_id :: Maybe Integer
    ,   success :: Maybe Int
    ,   failure :: Maybe Int
    ,   canonical_ids :: Maybe Int
    ,   results :: [MRes]
    ,   newRegids :: [(RegId,RegId)] -- ^ regIds that need to be replaced.
    ,   unRegistered :: [RegId] -- ^ regIds that need to be removed.
    ,   toReSend :: [RegId] -- ^ regIds that I need to resend the message to,
                            -- because there was an internal problem in the GCM servers.
    } deriving Show

instance Default GCMresult where
    def = GCMresult {
        multicast_id = Nothing
    ,   success = Nothing
    ,   failure = Nothing
    ,   canonical_ids = Nothing
    ,   results = []
    ,   newRegids = []
    ,   unRegistered = []
    ,   toReSend = []
    }


ifNotDef :: (ToJSON a,MonadWriter [Pair] m,Eq a)
            => Text
            -> (GCMmessage -> a)
            -> GCMmessage
            -> m ()
ifNotDef label f msg = if f def /= f msg
                        then tell [(label .= (f msg))]
                        else tell []

instance ToJSON GCMmessage where
    toJSON msg = object $ execWriter $ do
                                        ifNotDef cREGISTRATION_IDS registration_ids msg
                                        ifNotDef cNOTIFICATION_KEY notification_key msg
                                        ifNotDef cNOTIFICATION_KEY_NAME notification_key_name msg
                                        ifNotDef cTIME_TO_LIVE time_to_live msg
                                        ifNotDef cDATA data_object msg
                                        ifNotDef cCOLLAPSE_KEY collapse_key msg
                                        ifNotDef cRESTRICTED_PACKAGE_NAME restricted_package_name msg
                                        ifNotDef cDELAY_WHILE_IDLE delay_while_idle msg
                                        ifNotDef cDRY_RUN dry_run msg

