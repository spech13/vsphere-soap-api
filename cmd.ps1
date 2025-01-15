$global:rootPath = $(get-location).Path
$global:sdk = "https://host-name/sdk"
$global:cns = "https://host-name/vsanHealth"

$global:headers = @{
  "content-type"="text/xml;charset=UTF-8";
  "Soapaction"="urn:vsan/vSAN 7.0U3"
}

function global:get-session{
    $cookie = New-Object System.Net.Cookie("vmware_soap_session", $(get-content "$rootPath\caches\cookies"))
    $cookie.domain = "vc-kuber-nord.dtln.local"
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.cookies.add($cookie)
    return $session
}

function global:vSphereLogin{
  param([string]$userName, [string]$password)
  $body = $(get-content "$rootPath\requests\login.xml") -f @($userName, $password)

  [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
  $response = invoke-webrequest $sdk -method post -headers $headers -body $body -sessionvariable session
  $response.content > "$rootPath\responses\login.xml"
  $response.statuscode

  $cookie = $session.cookies.getcookies($sdk).value
  $cookie.substring(1, $cookie.length-2) > "$rootPath\caches\cookies"
}

function global:vSphereLogout{
  $body = get-content "$rootPath\requests\logout.xml"
  [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
  $response = invoke-webrequest $sdk -method post -headers $headers -body $body -websession $(get-session)
  $response.statuscode
}

function global:CreateVolume{
  param([string]$volumeName, [string]$datastoreId, [string]$clusterName, [int]$capacity, [switch]$verbose, [switch]$past)
  if($past){
    $cache = get-content "$rootPath\caches\create-volume"
    return @{volumeName=$cache[0]; clusterName=$cache[1]; datastoreId=$cache[2]; capacity=$cache[3]}
  }

  $body = $(get-content "$rootPath\requests\create-volume.xml") -f @(
    $volumeName, $datastoreId, $clusterName, $clusterName, $clusterName, $clusterName, $capacity)

  [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
  $response = invoke-webrequest $cns -method post -headers $headers -body $body -websession $(get-session)
  $response.content > "$rootPath\responses\create-volume.xml"

  [xml]$content = $response.content
  $taskId = $content.Envelope.Body.CnsCreateVolumeResponse.returnval.'#text'

  if($taskId){
    $taskId > "$rootPath\caches\report"
    $volumeName, $clusterName, $datastoreId, $capacity > "$rootPath\caches\create-volume"
    if($verbose){
      return $response.content
    }else{
      return @{taskId=$taskId}
    }
  }
}

function global:DeleteVolume{
  param([string]$volumeId, [switch]$verbose, [switch]$past)
  if($past){
    $cache = get-content "$rootPath\caches\delete-volume"
    return @{volumeId=$cache}
  }
  $body = $(get-content "$rootPath\requests\delete-volume.xml") -f @($volumeId)

  [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
  $response = wget $cns -method post -headers $headers -body $body -websession $(get-session)
  $response.content > "$rootPath\responses\delete-volume.xml"

  [xml]$content = $response.content
  $taskId = $content.Envelope.Body.CnsDeleteVolumeResponse.returnval.'#text'

  if($taskId){
    $taskId > "$rootPath\caches\report"
    $volumeId > "$rootPath\caches\delete-volume"
    if(-not $verbose){
      return @{taskId=$taskId}
    }else{
      return $response.content
    }
  }
}

function global:AttachVolume{
  param([string]$volumeId, [string]$nodeId, [switch]$verbose, [switch]$past)
  if($past){
    $cache = get-content "$rootPath\caches\attach-volume"
    return @{volumeId=$cache[0]; nodeId=$cache[1]}
  }

  $body = $(get-content "$rootPath\requests\attach-volume.xml") -f @($volumeId, $nodeId)

  [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
  $response = invoke-webrequest $cns -method post -headers $headers -body $body -websession $(get-session)
  $response.content > "$rootPath\responses\attach-volume.xml"

  [xml]$content = $response.content
  $taskId = $content.Envelope.Body.CnsAttachVolumeResponse.returnval.'#text'  
  
  if($response.statuscode -eq 200){
    $taskId > "$rootPath\caches\report"
    $volumeId, $nodeId > "$rootPath\caches\attach-volume"
    if(-not $verbose){
      return @{taskId=$taskId}
    }else{
      return resposne.content
    }
  }
}

function global:DetachVolume{
  param([string]$volumeId, [string]$nodeId, [switch]$verbose, [switch]$past)
  if($past){
    $cache = get-content "$rootPath\caches\detach-volume"
    return @{volumeId=$cache[0]; nodeId=$cache[1]}
  }

  $body = $(get-content "$rootPath\requests\detach-volume.xml") -f @($volumeId, $nodeId)

  [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
  $response = invoke-webrequest $cns -method post -headers $headers -body $body -websession $(get-session)
  $response.content > "$rootPath\responses\detach-volume.xml"

  [xml]$content = $response.content
  $taskId = $content.Envelope.Body.CnsDetachVolumeResponse.returnval.'#text'
  
  if($taskId){
    $taskId > "$rootPath\caches\report"
    $volumeId, $nodeId > "$rootPath\caches\detach-volume"
    if(-not $verbose){
      return @{taskId=$taskId}
    }else{
      return resposne.content
    }
  }
}

function global:ExpandVolume{
  param([string]$volumeId, [int]$capacity, [switch]$verbose, [switch]$past)
  if($past){
    $cache = get-content "$rootPath\caches\expand-volume"
    return @{volumeId=$cache[0]; capacity=$cache[1]}
  }

  $body = $(get-content "$rootPath\requests\expand-volume.xml") -f @($volumeId, $capacity)

  [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
  $response = invoke-webrequest $cns -method post -headers $headers -body $body -websession $(get-session)
  $response.content > "$rootPath\responses\expand-volume.xml"

  [xml]$content = $response.content
  $taskId = $content.Envelope.Body.CnsExtendVolumeResponse.returnval.'#text'

  if($taskId){
    $taskId > "$rootPath\caches\report"
    $volumeId, $capacity > "$rootPath\caches\expand-volume"
    if(-not $verbose){
      return @{taskId=$taskId}
    }else{
      return resposne.content
    }
  }
}

function global:ListVolumes{
  param([string]$clusterName, [switch]$verbose, [switch]$past)
  if($past){
    $cache = get-content "$rootPath\caches\list-volumes"
    return @{clusterName=$cache}
  }

  $body = (get-content "$rootPath\requests\list-volumes.xml") -f ($clusterName)

  [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
  $response = wget $cns -method post -headers $headers -body $body -websession $(get-session)
  $response.content > "$rootPath\responses\list-volumes.xml"
  
  if($response.statuscode -eq 200){
    $clusterName > "$rootPath\caches\list-volumes"
    if(-not $verbose){
      [xml]$content = $response.content
      $content.Envelope.Body.CnsQueryAllVolumeResponse.returnval.volumes | ForEach-Object {"id: $($_.volumeId.id), type: $($_.volumeType)"}
    }else{
      return respose.content
    }
  }
}

function global:RestoreVolume{
  param([string]$volumeName, [string]$volumeId, [string]$snapshotId, [string]$datastoreId, [switch]$verbose, [switch]$past)
  if($past){
    $cache = get-content "$rootPath\caches\restore-volume"
    return @{volumeName=$cache[0]; volumeId=$cache[1]; snapshotId=$cache[2]; datastoreId=$cache[3]}
  }

  $body = $(get-content "$rootPath\requests\restore-volume.xml") -f @(
    $volumeId, $datastoreId, $snapshotId, $volumeName)

  [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
  $response = invoke-webrequest $sdk -method post -headers $headers -body $body -websession $(get-session)
  $response.content > "$rootPath\responses\restore-volume.xml"

  [xml]$content = $response.content
  $taskId = $content.Envelope.Body.CnsDetachVolumeResponse.returnval.'#text'

  if($taskId){
    $taskId > "$rootPath\caches\report"
    $volumeName, $volumeId, $snapshotId, $datastoreId > "$rootPath\caches\restore-volume"
    if(-not $verbose){
      return @{taskId=$taskId}
    }else{
      return resposne.content
    }
  }
}

function global:CreateSnapshot{
  param([string]$volumeId, [string]$datastoreId, [switch]$verbose, [switch]$past)
  if($past){
    $cache = get-content "$rootPath\caches\create-snapshot"
    return @{volumeId=$cache[0]; datastoreId=$cache[1];}
  }

  $body = $(get-content "$rootPath\requests\create-snapshot.xml") -f @(
    $volumeId, $datastoreId, "Snapshot of volume $volumeId.")

  [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
  $response = invoke-webrequest $sdk -method post -headers $headers -body $body -websession $(get-session)
  $response.content > "$rootPath\responses\create-snapshot.xml"

  [xml]$content = $response.content
  $taskId = $content.Envelope.Body.VStorageObjectCreateSnapshot_TaskResponse.returnval.'#text'
  
  if($taskId){
    $taskId > "$rootPath\caches\report"
    $volumeId, $datastoreId > "$rootPath\caches\create-snapshot"
    if(-not $verbose){
      return @{taskId=$taskId}
    }else{
      return resposne.content
    }
  }
}

function global:DeleteSnapshot{
  param([string]$volumeId, [string]$datastoreId, [string]$snapshotId, [switch]$verbose, [switch]$past)
  if($past){
    $cache = get-content "$rootPath\caches\delete-snapshot"
    return @{volumeId=$cache[0]; datastoreId=$cache[1]; snapshotId=$cache[2]}
  }

  $body = $(get-content "$rootPath\requests\delete-snapshot.xml") -f @(
    $volumeId, $datastoreId, $snapshotId)

  [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
  $response = invoke-webrequest $sdk -method post -headers $headers -body $body -websession $(get-session)
  $response.content > "$rootPath\responses\delete-snapshot.xml"

  [xml]$content = $response.content
  $taskId = $content.Envelope.Body.DeleteSnapshot_TaskResponse.returnval.'#text'
  
  if($taskId){
    $taskId > $env:task_id_path
    $volumeId, $datastoreId, $snapshotId > "$rootPath\caches\delete-snapshot"
    if(-not $verbose){
      return @{taskId=$taskId}
    }else{
      return resposne.content
    }
  }
}

function global:GetSnapshot{
  param([string]$volumeId, [string]$datastoreId, [switch]$verbose, [switch]$past)
  if($past){
    $cache = get-content "$rootPath\caches\get-snapshot"
    return @{volumeId=$cache[0]; datastoreId=$cache[1]}
  }
  $body = $(get-content "$rootPath\requests\get-snapshot.xml") -f @($volumeId, $datastoreId)

  [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
  $response = invoke-webrequest $sdk -method post -headers $headers -body $body -websession $(get-session)
  $response.content > "$rootPath\responses\get-snapshot.xml"

  [xml]$content = $response.content
  $config = $content.Envelope.Body.RetrieveVStorageObjectResponse.returnval.config
  
  if($config){
    $volumeId, $datastoreId > "$rootPath\caches\get-snapshot"
    if(-not $verbose){
      write-host "volumeId: $($config.id.id)"
      write-host "capacityMiB: $($config.capacityInMb)"
      $parent = $config.backing

      $o = ""
      write-host "Snapshots tree from last to first:"
      while($parent){
        write-host "$o$($parent.filePath)"
        $o = $o + " "
        $parent = $parent.parent
      }
    }else{
      return response.content
    }
  }
}

function global:ListSnapshots{
  param([string]$volumeId, [string]$datastoreId, [switch]$verbose)
  $body = $(get-content "$rootPath\requests\list-snapshots.xml") -f @($volumeId, $datastoreId)

  [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
  $response = invoke-webrequest $sdk -method post -headers $headers -body $body -websession $(get-session)
  $response.content > "$rootPath\responses\list-snapshots.xml"

  if($response.statuscode -eq 200){
    if(-not $verbose){
      [xml]$content = $response.content
      $content.Envelope.Body.RetrieveSnapshotInfoResponse.returnval.snapshots | ForEach-Object {"id: $($_.id.id), desc: $($_.description)"}
    }else{
      return response.content
    }
  }
}

function global:GetNodeUUIDByName{
  param([string]$nodeName, [switch]$verbose, [switch]$past)
  if($past){
    $cache = get-content "$rootPath\cache\get-node-id-by-name.xml"
    return @{NodeID=$cache}
  }

  $body = $(get-content "$rootPath\requests\get-node-id-by-name.xml") -f @($nodeName)
  [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
  $response = invoke-webrequest $sdk -method post -headers $headers -body $body -websession $(get-session)
  $response.content > "$rootPath\responses\get-node-id-by-name.xml"

  [xml]$content = $response.content
  $nodeId = $content.Envelope.Body.FindByDnsNameResponse.returnval.'#text'

  if($nodeId){
    if(-not $verbose){
      return @{NodeID=$nodeId}
    }else{
      return $response.content
    }
  }
}

function global:GetNodeByUUID{
  param([string]$nodeID)

  $body = get-content "$rootPath\requests\create-collector.xml"
  [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
  $response = invoke-webrequest $sdk -method post -headers $headers -body $body -websession $(get-session)
  $response.content > "$rootPath\responses\create-collector.xml"
  
  [xml]$content = $response.content
  $pcID = $content.Envelope.Body.CreatePropertyCollectorResponse.returnval.'#text'

  $body = $(get-content "$rootPath\requests\get-node-info.xml") -f @($nodeID)
  $response = invoke-webrequest $sdk -method post -headers $headers -body $body -websession $(get-session)
  $response.content > "$rootPath\responses\get-node-info.xml"

  [xml]$content = $response.content
  $returnval = $content.Envelope.Body.RetrievePropertiesResponse.returnval
  if($returnval){
    $nodeInfo = @{}
    foreach($prop in $returnval.propSet){
      $nodeInfo[$prop.name] = $prop.val
    }
  }

  if($pcID){
    $body = $(get-content "$rootPath\requests\destroy-collector.xml") -f @($pcID)
    $response = invoke-webrequest $sdk -method post -headers $headers -body $body -websession $(get-session)
  }

  if(-not ($nodeInfo.Count -eq 0)){
    return $nodeInfo
  }
}

function global:Report{
  param([string]$taskId)
  if($taskId -eq ""){
    $taskId = get-content "$rootPath\caches\report"
  }

  $body = get-content "$rootPath\requests\create-collector.xml"
  [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
  $response = invoke-webrequest $sdk -method post -headers $headers -body $body -websession $(get-session)
  $response.content > "$rootPath\responses\create-collector.xml"

  $createdPC = $($response.statuscode -eq 200)
  [xml]$content = $response.content
  $pcId = $content.Envelope.Body.CreatePropertyCollectorResponse.returnval.'#text'

  $body = $(get-content "$rootPath\requests\report.xml") -f @($taskId)
  $response = invoke-webrequest $sdk -method post -headers $headers -body $body -websession $(get-session)
  $response.content > "$rootPath\responses\report.xml"
  [xml]$content = $response.content
  $returnval = $content.Envelope.Body.RetrievePropertiesResponse.returnval

  if($returnval){
    $taskInfo = @{}
    foreach($prop in $returnval.propSet){
      $taskInfo[$prop.name] = $prop.val
    }
  }
  
  if($createdPC){
    $body = $(get-content "$rootPath\requests\destroy-collector.xml") -f @($pcId)
    $response = invoke-webrequest $sdk -method post -headers $headers -body $body -websession $(get-session)
  }

  if(-not ($taskInfo.Count -eq 0)){
    return $taskInfo
  }
}